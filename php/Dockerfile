ARG PHP_VERSION

FROM php:${PHP_VERSION}-fpm

# ============= 镜像源配置 =============
ARG USE_CHINA_MIRROR=false
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        echo "[INFO] Configuring China mirrors (Aliyun+USTC)"; \
        sed -i 's|http://deb.debian.org|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
        sed -i 's|http://security.debian.org|https://mirrors.aliyun.com|g' /etc/apt/sources.list && \
        sed -i 's|http://deb.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list && \
        sed -i 's|http://security.debian.org|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list && \
        echo "[INFO] China mirrors configured successfully"; \
    else \
        echo "[INFO] Using default apt sources"; \
    fi

# ============= 基础依赖安装 =============
RUN echo "[INFO] Installing base dependencies..." && \
    apt-get update && apt-get install -y \
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
        libxpm-dev && \
    echo "[INFO] Base dependencies installed"

# ============= FFmpeg 安装 =============
ARG USE_FFMPEG=false
RUN if [ "$USE_FFMPEG" = "true" ]; then \
        echo "[INFO] Starting FFmpeg 7.0.2 installation"; \
        echo "[STEP] Installing build dependencies..." && \
        apt-get update && apt-get install -y \
            wget \
            build-essential \
            yasm \
            nasm \
            libtool \
            autoconf \
            automake \
            pkg-config \
            libx264-dev \
            libmp3lame-dev \
            libx265-dev && \
        echo "[STEP] Installing opencore-amr..." && \
        cd /tmp && \
        wget https://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.6.tar.gz && \
        tar xvf opencore-amr-0.1.6.tar.gz && \
        cd opencore-amr-0.1.6 && \
        ./configure --prefix=/usr && \
        make && \
        make install && \
        cd .. && \
        rm -rf opencore-amr-0.1.6* && \
        echo "[STEP] Installing FFmpeg..." && \
        wget https://ffmpeg.org/releases/ffmpeg-7.0.2.tar.gz && \
        tar xvf ffmpeg-7.0.2.tar.gz && \
        cd ffmpeg-7.0.2 && \
        ./configure --prefix=/usr \
            --enable-shared \
            --enable-gpl \
            --enable-libx264 \
            --enable-libx265 \
            --enable-libopencore-amrnb \
            --enable-libopencore-amrwb \
            --enable-version3 \
            --enable-libmp3lame \
            --disable-static && \
        make -j$(nproc) && \
        make install && \
        ldconfig && \
        cd .. && \
        rm -rf ffmpeg-7.0.2* && \
        echo "[SUCCESS] FFmpeg installed successfully"; \
    else \
        echo "[INFO] Skipping FFmpeg installation (USE_FFMPEG=false)"; \
    fi

# ============= 工具安装 =============
RUN echo "[INFO] Installing utilities..." && \
    apt-get update && apt-get install -y \
        curl \
        git \
        vim \
        unzip && \
    echo "[INFO] Utilities installed"

# ============= PHP 扩展安装 =============
RUN echo "[INFO] Installing PHP extensions..." && \
    docker-php-ext-install -j$(nproc) \
        bcmath \
        ctype \
        fileinfo \
        mbstring \
        pdo \
        xml \
        pdo_mysql \
        mysqli \
        zip \
        intl \
        opcache \
        gd && \
    echo "[INFO] PHP extensions installed"

# ============= Redis 扩展 =============
RUN echo "[INFO] Installing Redis extension..." && \
    pecl install redis && \
    docker-php-ext-enable redis && \
    echo "[INFO] Redis extension installed"

# ============= Composer 安装 =============
RUN echo "[INFO] Installing Composer..." && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        echo "[INFO] Configuring Composer China mirror"; \
        composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/; \
    else \
        echo "[INFO] Using default Composer repository"; \
    fi && \
    echo "[INFO] Composer setup completed"

# ============= 清理工作 =============
RUN echo "[INFO] Cleaning up..." && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "[INFO] Cleanup completed"

# ============= 时区设置 =============
RUN echo "[INFO] Setting timezone to Asia/Shanghai" && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    echo "[INFO] Timezone configured"

WORKDIR /var/www/html

# ============= 健康检查 =============
HEALTHCHECK --interval=30s --timeout=3s \
    CMD php-fpm -t || exit 1

# ============= 最终信息 =============
RUN echo "[INFO] Docker image build completed successfully"
