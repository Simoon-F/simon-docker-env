
# Simon Docker Environment

A flexible and customizable Docker-based development environment.

---

## Features

- **Service Isolation**: Each service (PHP, Nginx, MySQL, Redis) runs in its own container.
- **Customizable Configurations**: Configure MySQL and Redis via `.env` and config files.
- **PHP Version Switching**: Dynamically manage PHP containers — switch versions instantly without rebuilding.
- **China Optimization**: Optional use of Chinese mirrors for faster downloads.
- **Data Persistence**: Redis and MySQL data are persisted in `redis/data` and `mysql-data` directories.

---

## Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/simon-docker-env.git
cd simon-docker-env
```

### 2. Configure Environment Variables

Rename `.env.example` to `.env` and update the values:

```env
# Project root directory
APP_CODE_PATH_HOST=../your-project-root

# MySQL configuration
MYSQL_VERSION=8.0.34
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=mydb
MYSQL_USER=user
MYSQL_PASSWORD=password

# Redis configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redisadmin

# phpMyAdmin configuration
PMA_HOST=db
PMA_PORT=3306

# Use Chinese mirrors (true/false)
USE_CHINA_MIRROR=false

# Use FFmpeg (true/false)
USE_FFMPEG=true
```

### 3. Start Infrastructure

```bash
docker compose up -d
```

This will start:
- **Nginx**: Web server (port 80)
- **MySQL**: Database server (port 3306)
- **Redis**: Redis server (port 6379)

### 4. Start PHP

```bash
./switch-version.sh php 8.3.16
```

The first run will build the image (one-time only). After that, version switches are instant.

---

## Project Structure

```plaintext
simon-docker-env/
├── docker-compose.yml        # Infrastructure (nginx, mysql, redis)
├── switch-version.sh         # PHP/MySQL version switcher (macOS/Linux)
├── switch-version.ps1        # PHP/MySQL version switcher (Windows)
├── .env                      # Environment variables
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── default.conf
│       ├── omelink-service.conf
│       ├── aixvo-service.conf
│       └── aixvo-link-service.conf
├── php/
│   ├── Dockerfile            # PHP image definition (any version)
│   └── custom.ini            # PHP custom configuration
├── mysql/
│   └── Dockerfile
├── redis/
│   ├── data/
│   └── redis.conf
├── mysql-data/
└── .gitignore
```

---

## PHP Version Management

PHP containers are dynamically managed by `switch-version.sh` — they are **not** defined in docker-compose.yml.

### Switch Versions

```bash
./switch-version.sh php 8.4.1       # Switch to PHP 8.4.1
./switch-version.sh php 8.3.16      # Switch back to PHP 8.3.16
```

### Add New Versions

No configuration changes needed — just specify the version:

```bash
./switch-version.sh php 8.5.0       # Auto-builds image + switches
./switch-version.sh php 8.6.0       # Same
```

Any version available as `php:X.X.X-fpm` on Docker Hub will work.

### Check Current Status

```bash
./switch-version.sh php
```

Output example:
```
=== PHP Version Status ===

Active: PHP 8.4.1

Installed versions:
  8.3.16  [stopped]
  8.4.1  [running]
```

### How It Works

```
./switch-version.sh php 8.4.1

  1. Check if image simon-php:8.4.1 exists
     ├─ No  → docker build (one-time)
     └─ Yes → skip

  2. Start container simon_php84
     └─ docker run -d simon-php:8.4.1

  3. Update nginx $php_upstream → simon_php84:9000
     └─ nginx -s reload (instant, no downtime)

  4. Stop old container simon_php83 (free memory)
```

---

## MySQL Version Switching

MySQL version switching requires a rebuild:

```bash
./switch-version.sh mysql 8.0.34
```

---

## Managing Containers

- **Start Containers**:
  ```bash
  docker compose up -d
  ```
- **Stop Containers**:
  ```bash
  docker compose down
  ```
- **View Logs**:
  ```bash
  docker logs -f simon_php83        # PHP 8.3 logs
  docker logs -f simon_php84        # PHP 8.4 logs
  docker logs -f simon_nginx        # Nginx logs
  docker logs -f simon_db           # MySQL logs
  docker logs -f simon_redis        # Redis logs
  ```
- **Enter a Container**:
  ```bash
  docker exec -it simon_php83 bash  # Enter PHP 8.3 container
  docker exec -it simon_db bash     # Enter MySQL container
  docker exec -it simon_redis bash  # Enter Redis container
  ```

---

## Customization

### Add a New Project

1. Add a new Nginx configuration file in `nginx/conf.d/` (e.g., `project.conf`).
2. Place your project files in the directory specified by `APP_CODE_PATH_HOST` in `.env`.
3. Restart the Nginx container:
   ```bash
   docker compose restart nginx
   ```

### Nginx Configuration Example

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

> **Note**: The `set $php_upstream` line is automatically updated by `switch-version.sh`. Manual changes will be overwritten on the next switch.

### Use Chinese Mirrors

Set `USE_CHINA_MIRROR=true` in `.env` to use Chinese mirrors for faster downloads.

### Configuration Files

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

## Windows Users

Use `switch-version.ps1` (PowerShell):

```powershell
.\switch-version.ps1 php 8.4.1       # Switch PHP version
.\switch-version.ps1 php              # View current status
.\switch-version.ps1 mysql 8.0.34     # Switch MySQL version
```

---

## Contributing

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Submit a pull request.

---

## License

This project is open-source and available under the MIT License.

---

## Support

If you encounter any issues or have questions, feel free to open an issue on GitHub or contact the maintainer.

Enjoy your development experience with Simon Docker Environment! 🚀
