ARG PHP_VERSION

FROM php:${PHP_VERSION}-cli

ARG USE_CHINA_MIRROR
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        sed -i 's|http://deb.debian.org|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
        sed -i 's|http://security.debian.org|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
        sed -i 's|http://deb.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list && \
        sed -i 's|http://security.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list; \
    fi

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

RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    unzip

RUN docker-php-ext-install -j$(nproc) bcmath ctype fileinfo mbstring pdo xml pdo_mysql mysqli zip intl opcache

RUN pecl install redis && docker-php-ext-enable redis

# 安装 Composer 并根据 USE_CHINA_MIRROR 配置选择镜像源
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/; \
    fi

# 设置工作目录
WORKDIR /var/www/html

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

# 清理缓存
RUN apt-get clean && rm -rf /var/lib/apt/lists/*