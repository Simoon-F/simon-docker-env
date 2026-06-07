
# Simon Docker 环境

一个灵活且可定制的 Docker 开发环境。

---

## 功能

- **服务隔离**：每个服务（PHP、Nginx、MySQL、Redis）运行在独立的容器中。
- **可定制的配置**：通过 `.env` 和配置文件配置 MySQL 和 Redis。
- **PHP 版本秒切**：动态管理 PHP 容器，切换版本无需重新构建镜像。
- **中国优化**：可选使用国内镜像加速依赖下载。
- **数据持久化**：Redis 和 MySQL 数据保存在 `redis/data` 和 `mysql-data` 目录中。

---

## 前提条件

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)

---

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/your-username/simon-docker-env.git
cd simon-docker-env
```

### 2. 配置环境变量

将 `.env.example` 重命名为 `.env`，并根据需要更新值：

```env
# 项目目录
APP_CODE_PATH_HOST=../your-project-root

# MySQL 配置
MYSQL_VERSION=8.0.34
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=mydb
MYSQL_USER=user
MYSQL_PASSWORD=password

# Redis 配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redisadmin

# phpMyAdmin 配置
PMA_HOST=db
PMA_PORT=3306

# 使用国内镜像（true/false）
USE_CHINA_MIRROR=false

# 使用 FFmpeg（true/false）
USE_FFMPEG=true
```

### 3. 启动基础设施

```bash
docker compose up -d
```

这将启动：
- **Nginx**：Web 服务器（端口 80）
- **MySQL**：数据库服务器（端口 3306）
- **Redis**：Redis 服务器（端口 6379）

### 4. 启动 PHP

```bash
./switch-version.sh php 8.3.16
```

首次运行会自动构建镜像（只需一次），之后切换版本秒切。

---

## 项目结构

```plaintext
simon-docker-env/
├── docker-compose.yml        # 基础设施定义（nginx、mysql、redis）
├── switch-version.sh         # PHP/MySQL 版本切换脚本（macOS/Linux）
├── switch-version.ps1        # PHP/MySQL 版本切换脚本（Windows）
├── .env                      # 环境变量配置
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── default.conf
│       ├── omelink-service.conf
│       ├── aixvo-service.conf
│       └── aixvo-link-service.conf
├── php/
│   ├── Dockerfile            # PHP 镜像定义（支持任意版本）
│   └── custom.ini            # PHP 自定义配置
├── mysql/
│   └── Dockerfile
├── redis/
│   ├── data/
│   └── redis.conf
├── mysql-data/
└── .gitignore
```

---

## PHP 版本管理

PHP 容器由 `switch-version.sh` 动态管理，**不在 docker-compose.yml 中定义**。

### 切换版本

```bash
./switch-version.sh php 8.4.1       # 切换到 PHP 8.4.1
./switch-version.sh php 8.3.16      # 切换回 PHP 8.3.16
```

### 添加新版本

无需修改任何配置文件，直接指定版本号即可：

```bash
./switch-version.sh php 8.5.0       # 自动构建镜像 + 切换
./switch-version.sh php 8.6.0       # 同上
```

版本号只要是 Docker Hub 上 `php:X.X.X-fpm` 存在的即可。

### 查看当前状态

```bash
./switch-version.sh php
```

输出示例：
```
=== PHP Version Status ===

Active: PHP 8.4.1

Installed versions:
  8.3.16  [stopped]
  8.4.1  [running]
```

### 工作原理

```
./switch-version.sh php 8.4.1

  1. 检查镜像 simon-php:8.4.1 是否存在
     ├─ 不存在 → docker build（一次性构建）
     └─ 已存在 → 跳过

  2. 启动容器 simon_php84
     └─ docker run -d simon-php:8.4.1

  3. 更新 nginx 配置中的 $php_upstream → simon_php84:9000
     └─ nginx -s reload（秒切，不中断服务）

  4. 停止旧容器 simon_php83（释放内存）
```

---

## MySQL 版本切换

MySQL 版本切换需要重新构建镜像：

```bash
./switch-version.sh mysql 8.0.34
```

---

## 管理容器

- **启动容器**:
  ```bash
  docker compose up -d
  ```
- **停止容器**:
  ```bash
  docker compose down
  ```
- **查看日志**:
  ```bash
  docker logs -f simon_php83        # 查看 PHP 8.3 日志
  docker logs -f simon_php84        # 查看 PHP 8.4 日志
  docker logs -f simon_nginx        # 查看 Nginx 日志
  docker logs -f simon_db           # 查看 MySQL 日志
  docker logs -f simon_redis        # 查看 Redis 日志
  ```
- **进入容器**:
  ```bash
  docker exec -it simon_php83 bash  # 进入 PHP 8.3 容器
  docker exec -it simon_db bash     # 进入 MySQL 容器
  docker exec -it simon_redis bash  # 进入 Redis 容器
  ```

---

## 自定义环境

### 添加新项目

1. 在 `nginx/conf.d/` 中添加一个新的 Nginx 配置文件（例如 `project.conf`）。
2. 将你的项目文件放置在 `.env` 中 `APP_CODE_PATH_HOST` 指定的目录中。
3. 重启 Nginx 容器：
   ```bash
   docker compose restart nginx
   ```

### Nginx 配置示例

```nginx
server {
    listen 80;
    server_name project.local;
    root /var/www/html/project/public;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        resolver 127.0.0.11 valid=30s;
        set $php_upstream simon_php83:9000;
        include fastcgi_params;
        fastcgi_pass $php_upstream;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }
}
```

> **注意**：`set $php_upstream` 行由 `switch-version.sh` 自动更新，手动修改会在下次切换时被覆盖。

### 使用中国镜像

在 `.env` 文件中设置 `USE_CHINA_MIRROR=true`，以使用国内镜像加速下载。

### 配置文件

- **PHP** (`php/custom.ini`):
  ```ini
  max_execution_time = 300
  upload_max_filesize = 100M
  post_max_size = 100M
  memory_limit = 256M
  ```

- **Redis** (`redis/redis.conf`):
  ```conf
  bind 0.0.0.0
  port 6379
  dir /data
  ```

---

## Windows 用户

Windows 用户使用 `switch-version.ps1`（PowerShell 脚本）：

```powershell
.\switch-version.ps1 php 8.4.1       # 切换 PHP 版本
.\switch-version.ps1 php              # 查看当前状态
.\switch-version.ps1 mysql 8.0.34     # 切换 MySQL 版本
```

---

## 贡献

1. Fork 该仓库。
2. 为你的功能或修复创建一个新分支。
3. 提交 Pull Request。

---

## 许可证

该项目是开源的，遵循 MIT 许可证。

---

## 支持

如果你遇到任何问题或有疑问，请在 GitHub 上提交 Issue 或联系维护者。

享受使用 Simon Docker 环境 的开发体验吧！🚀
