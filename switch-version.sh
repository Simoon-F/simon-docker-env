#!/bin/bash
set -e

# =============================================
# switch-version.sh - PHP/MySQL 版本动态管理
#
# PHP: 容器由脚本动态创建，切换只需改 nginx + reload
#   添加新版本: ./switch-version.sh php 8.5.0   (自动构建)
#   切换版本:   ./switch-version.sh php 8.4.1   (秒切)
#   查看当前:   ./switch-version.sh php
#
# MySQL: 更新 .env + 重新构建
# =============================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
NGINX_CONF_DIR="${PROJECT_DIR}/nginx/conf.d"
IMAGE_NAME="simon-php"
NETWORK="simon-docker-env_simon_network"

# 加载 .env
if [ -f "${PROJECT_DIR}/.env" ]; then
  export $(grep -v '^#' "${PROJECT_DIR}/.env" | xargs)
fi

APP_CODE_PATH_HOST="${APP_CODE_PATH_HOST:-../wwwroot}"
REDIS_HOST="simon_redis"
REDIS_PORT="6379"

show_status() {
  echo "=== PHP Version Status ==="
  echo ""

  # 从 nginx 配置读取当前活跃版本
  ACTIVE=$(grep 'set \$php_upstream' "${NGINX_CONF_DIR}/default.conf" 2>/dev/null | grep -oP 'simon_php[\d]+:\d+' | head -1)
  if [ -n "$ACTIVE" ]; then
    ACTIVE_VER=$(echo "$ACTIVE" | sed 's/simon_php//' | sed 's/:.*//' | sed 's/\(.\)/\1./')
    echo "Active: PHP ${ACTIVE_VER}"
  else
    echo "Active: none"
  fi

  echo ""
  echo "Installed versions:"
  docker images --format '{{.Tag}}' "${IMAGE_NAME}" 2>/dev/null | sort -V | while read tag; do
    CONTAINER="simon_php$(echo $tag | tr -d '.')"
    STATUS=$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || echo "stopped")
    if [ "$STATUS" == "true" ]; then
      echo "  $tag  [running]"
    else
      echo "  $tag  [stopped]"
    fi
  done

  if ! docker images --format '{{.Tag}}' "${IMAGE_NAME}" 2>/dev/null | grep -q .; then
    echo "  (none - run: ./switch-version.sh php <version>)"
  fi
}

build_php_image() {
  local VERSION=$1
  local IMAGE_TAG="${IMAGE_NAME}:${VERSION}"

  echo "📦 Building PHP ${VERSION} image (one-time)..."
  docker build \
    --build-arg PHP_VERSION="${VERSION}" \
    --build-arg USE_CHINA_MIRROR="${USE_CHINA_MIRROR:-false}" \
    --build-arg USE_FFMPEG="${USE_FFMPEG:-false}" \
    -t "${IMAGE_TAG}" \
    -f "${PROJECT_DIR}/php/Dockerfile" \
    "${PROJECT_DIR}/php"

  if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
  fi

  echo "✅ Image ${IMAGE_TAG} built successfully"
}

start_php_container() {
  local VERSION=$1
  local VERSION_COMPACT=$(echo "$VERSION" | tr -d '.')
  local CONTAINER="simon_php${VERSION_COMPACT}"
  local IMAGE_TAG="${IMAGE_NAME}:${VERSION}"

  # 如果容器已在运行，跳过
  if docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q "true"; then
    echo "✅ Container ${CONTAINER} is already running"
    return 0
  fi

  # 如果容器存在但已停止，删除
  docker rm -f "$CONTAINER" 2>/dev/null || true

  echo "🚀 Starting PHP ${VERSION} container..."
  docker run -d \
    --name "$CONTAINER" \
    --network "$NETWORK" \
    --restart unless-stopped \
    -v "${PROJECT_DIR}/../wwwroot:/var/www/html" \
    -v "${PROJECT_DIR}/php/custom.ini:/usr/local/etc/php/conf.d/custom.ini" \
    -e PHP_VERSION="${VERSION}" \
    -e REDIS_HOST="${REDIS_HOST}" \
    -e REDIS_PORT="${REDIS_PORT}" \
    "${IMAGE_TAG}"

  echo "✅ Container ${CONTAINER} started"
}

update_nginx() {
  local VERSION=$1
  local VERSION_COMPACT=$(echo "$VERSION" | tr -d '.')
  local CONTAINER="simon_php${VERSION_COMPACT}"

  # 更新所有 nginx 配置中的 $php_upstream 变量
  for conf in "${NGINX_CONF_DIR}"/*.conf; do
    if grep -q 'set \$php_upstream' "$conf" 2>/dev/null; then
      sed -i '' "s|set \$php_upstream .*;|set \$php_upstream ${CONTAINER}:9000;|" "$conf"
    fi
  done

  # reload nginx
  docker exec simon_nginx nginx -s reload 2>/dev/null && \
    echo "✅ Nginx reloaded" || \
    echo "⚠️  Nginx not running yet (will use new config on start)"
}

stop_old_php() {
  local NEW_VERSION=$1
  local NEW_COMPACT=$(echo "$NEW_VERSION" | tr -d '.')

  docker ps --format '{{.Names}}' | grep '^simon_php' | while read name; do
    if [ "$name" != "simon_php${NEW_COMPACT}" ]; then
      echo "⏹  Stopping old container: $name"
      docker stop "$name" >/dev/null
    fi
  done
}

# ========== Main ==========

if [ -z "$1" ]; then
  show_status
  exit 0
fi

TYPE=$1

if [ "$TYPE" == "php" ]; then
  if [ -z "$2" ]; then
    show_status
    exit 0
  fi

  VERSION=$2

  # 检查镜像是否存在，不存在则构建
  if ! docker image inspect "${IMAGE_NAME}:${VERSION}" &>/dev/null; then
    build_php_image "$VERSION"
  fi

  # 启动容器
  start_php_container "$VERSION"

  # 更新 nginx 指向
  update_nginx "$VERSION"

  # 停止旧的 PHP 容器（释放资源）
  stop_old_php "$VERSION"

  echo ""
  echo "✅ Switched to PHP ${VERSION}"
  echo ""
  echo "Verify:  docker exec simon_php$(echo $VERSION | tr -d '.') php -v"

elif [ "$TYPE" == "mysql" ]; then
  if [ -z "$2" ]; then
    echo "Usage: ./switch-version.sh mysql <version>"
    exit 1
  fi

  VERSION=$2
  sed -i '' "s|MYSQL_VERSION=.*|MYSQL_VERSION=${VERSION}|" .env
  echo "Switched MySQL to version ${VERSION}"

  docker compose down
  if ! docker compose build --no-cache mysql; then
    echo "❌ Build failed!"
    exit 1
  fi
  docker compose up -d
  echo "✅ MySQL switched to ${VERSION}"

else
  echo "Usage:"
  echo "  ./switch-version.sh php [version]    切换/查看 PHP 版本"
  echo "  ./switch-version.sh mysql <version>  切换 MySQL 版本"
  exit 1
fi
