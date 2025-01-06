
# Simon Docker Environment

A flexible and customizable Docker-based development environment.

---

## Features

- **Service Isolation**: Each service (PHP, Nginx, MySQL, Redis) runs in its own container.
- **Customizable Configurations**: Configure PHP, MySQL, and Redis via `.env` and config files.
- **Version Switching**: Easily switch PHP and MySQL versions.
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

# PHP version
PHP_VERSION=8.4

# MySQL configuration
MYSQL_VERSION=8.0
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
```

### 3. Start the Environment

Run the following command to start all services:

```bash
docker compose up -d
```

This will start:
- **Nginx**: Web server (port 80).
- **PHP**: PHP-FPM service.
- **MySQL**: Database server (port 3306).
- **Redis**: Redis server (port 6379).
- **phpMyAdmin**: Database management tool (port 8080).

---

## Project Structure

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

## Usage

### Switch PHP or MySQL Versions

Use the provided scripts to switch versions:

**macOS/Linux:**
```bash
./switch-version.sh php 8.3       # Switch PHP to version 8.3
./switch-version.sh mysql 5.7     # Switch MySQL to version 5.7
```

**Windows:**
```powershell
.\switch-version.ps1 php 8.3      # Switch PHP to version 8.3
.\switch-version.ps1 mysql 5.7    # Switch MySQL to version 5.7
```

### Manage Containers

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
  docker logs -f simon_php        # PHP logs
  docker logs -f simon_nginx        # Nginx logs
  docker logs -f simon_db         # MySQL logs
  docker logs -f simon_redis      # Redis logs
  ```
- **Enter a Container**:
  ```bash
  docker exec -it simon_php bash  # Enter PHP container
  docker exec -it simon_db bash   # Enter MySQL container
  docker exec -it simon_redis bash # Enter Redis container
  ```

---

## Customization

### Add a New Project

1. Add a new Nginx configuration file in `nginx/conf.d/` (e.g., `project2.conf`).
2. Place your project files in the directory specified by `APP_CODE_PATH_HOST` in `.env`.
3. Restart the Nginx container:
   ```bash
   docker compose restart nginx
   ```

### Use Chinese Mirrors

Set `USE_CHINA_MIRROR=true` in `.env` to use Chinese mirrors for faster downloads.

### Configuration Files

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
