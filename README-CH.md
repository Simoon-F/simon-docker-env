
# Simon Docker 环境

一个灵活且可定制的 Docker 开发环境。

---

## 功能

- **服务隔离**：每个服务（PHP、Nginx、MySQL、Redis）运行在独立的容器中。
- **可定制的配置**：通过 `.env` 和配置文件配置 PHP、MySQL 和 Redis。
- **版本切换**：轻松切换 PHP 和 MySQL 版本。
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

# PHP 版本
PHP_VERSION=8.4

# MySQL 配置
MYSQL_VERSION=8.0
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=mydb
MYSQL_USER=user
MYSQL_PASSWORD=password

# Redis 配置
REDIS_HOST=redis
REDIS_PORT=6379

# phpMyAdmin 配置
PMA_HOST=db
PMA_PORT=3306

# 使用国内镜像（true/false）
USE_CHINA_MIRROR=false
```

### 3. 启动环境

运行以下命令启动所有服务：

```bash
docker compose up -d
```

这将启动：
- **Nginx**：Web 服务器（端口 80）。
- **PHP**：PHP-FPM 服务。
- **MySQL**：数据库服务器（端口 3306）。
- **Redis**：Redis 服务器（端口 6379）。
- **phpMyAdmin**：数据库管理工具（端口 8080）。

---

## 项目结构

```plaintext
simon-docker-env/
├── docker compose.yml
├── nginx/
│   ├── conf.d/
│   │   ├── project1.conf
│   │   ├── project2.conf
│   └── nginx.conf
├── php/
│   └── Dockerfile
├── mysql/
│   └── Dockerfile
├── redis/
│   ├── data/
│   └── redis.conf
├── mysql-data/
├── .env
├── switch-version.sh
├── switch-version.ps1
└── .gitignore
```

---

## 使用方法

### 切换 PHP 或 MySQL 版本

使用提供的脚本切换版本：

**macOS/Linux:**
```bash
./switch-version.sh php 8.3       # 切换 PHP 到 8.3 版本
./switch-version.sh mysql 5.7     # 切换 MySQL 到 5.7 版本
```

**Windows:**
```powershell
.\switch-version.ps1 php 8.3      # 切换 PHP 到 8.3 版本
.\switch-version.ps1 mysql 5.7    # 切换 MySQL 到 5.7 版本
```

### 管理容器

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
  docker logs -f simon_php        # 查看 PHP 日志
  docker logs -f simon_nginx        # 查看 Nginx 日志
  docker logs -f simon_db         # 查看 MySQL 日志
  docker logs -f simon_redis      # 查看 Redis 日志
  ```
- **进入容器**:
  ```bash
  docker exec -it simon_php bash  # 进入 PHP 容器
  docker exec -it simon_db bash   # 进入 MySQL 容器
  docker exec -it simon_redis bash # 进入 Redis 容器
  ```

---

## 自定义环境

### 添加新项目

1. 在 `nginx/conf.d/` 中添加一个新的 Nginx 配置文件（例如 `project2.conf`）。
2. 将你的项目文件放置在 `.env` 中 `APP_CODE_PATH_HOST` 指定的目录中。
3. 重启 Nginx 容器：
   ```bash
   docker compose restart nginx
   ```

### 使用中国镜像

在 `.env` 文件中设置 `USE_CHINA_MIRROR=true`，以使用国内镜像加速下载。

### 配置文件

- **MySQL** (`mysql/my.cnf`):
  ```conf
  [mysqld]
  character-set-server = utf8mb4
  collation-server = utf8mb4_unicode_ci
  ```

- **Redis** (`redis/redis.conf`):
  ```conf
  bind 0.0.0.0
  port 6379
  dir /data
  ```

- **Nginx** (`nginx/conf.d/project1.conf`):
  ```nginx
  server {
      listen 80;
      server_name project1.local;
      root /var/www/html/project1/public;
      ...
  }
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
