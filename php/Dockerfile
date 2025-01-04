ARG PHP_VERSION

FROM php:${PHP_VERSION}-fpm

# 使用中国镜像
ARG USE_CHINA_MIRROR
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        sed -i 's|http://deb.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list && \
        sed -i 's|http://security.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list; \
    fi

# 安装系统依赖和 PHP 扩展所需的库
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libpq-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    libxpm-dev

# 安装 PHP 扩展
RUN docker-php-ext-install -j$(nproc) bcmath ctype fileinfo mbstring pdo xml pdo_mysql mysqli zip intl opcache

# 安装 Redis 扩展
RUN pecl install redis && docker-php-ext-enable redis

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /var/www/html

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone