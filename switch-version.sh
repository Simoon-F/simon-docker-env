#!/bin/bash
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ./switch-version.sh <php|mysql> <version>"
  exit 1
fi

TYPE=$1
VERSION=$2

if [ "$TYPE" == "php" ]; then
  # 更新 PHP 版本
  sed -i '' "s|PHP_VERSION=.*|PHP_VERSION=${VERSION}|" .env
  echo "Switched PHP to version ${VERSION}"
elif [ "$TYPE" == "mysql" ]; then
  # 更新 MySQL 版本
  sed -i '' "s|MYSQL_VERSION=.*|MYSQL_VERSION=${VERSION}|" .env
  echo "Switched MySQL to version ${VERSION}"
else
  echo "Invalid type. Use 'php' or 'mysql'."
  exit 1
fi

# 重启容器
docker compose down
docker compose up -d