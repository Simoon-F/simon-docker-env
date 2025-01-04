# 使用 ARG 定义变量
ARG PHP_VERSION

# 使用官方 PHP-FPM 镜像作为基础镜像
FROM php:${PHP_VERSION}-fpm

ARG USE_CHINA_MIRROR=false
# 根据 USE_CHINA_MIRROR 配置选择镜像源
RUN if [ "${USE_CHINA_MIRROR:-false}" = "true" ]; then \
      sed -i 's#deb.debian.org#mirrors.tuna.tsinghua.edu.cn#g' /etc/apt/sources.list.d/debian.sources && \
      sed -i 's#security.debian.org#mirrors.tuna.tsinghua.edu.cn#g' /etc/apt/sources.list.d/debian.sources && \
      echo "Updated sources.list:" && cat /etc/apt/sources.list.d/debian.sources; \
  fi


# 安装系统依赖
RUN apt-get update && apt-get install -y \
        unzip \
        git

# 安装 Laravel 必需的扩展
RUN docker-php-ext-install \
        bcmath \
        ctype \
        fileinfo \
        json \
        mbstring \
        openssl \
        pdo \
        tokenizer \
        xml \
        pdo_mysql \
        mysqli \
        zip

# 安装 Redis 扩展
RUN pecl install redis && docker-php-ext-enable redis

# 安装 Composer 并根据 USE_CHINA_MIRROR 配置选择镜像源
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/; \
fi

# 设置工作目录
WORKDIR /var/www/html

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

# 清理缓存
RUN apt-get clean && rm -rf /var/lib/apt/lists/*