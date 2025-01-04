ARG PHP_VERSION

FROM php:${PHP_VERSION}-cli

# 安装常用工具
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    unzip

# 安装 Composer 并根据 USE_CHINA_MIRROR 配置选择镜像源
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/; \
    fi

# 设置工作目录
WORKDIR /var/www/html