# 使用 ARG 定义变量
ARG MYSQL_VERSION

# 使用官方 MySQL 镜像作为基础镜像
FROM mysql:${MYSQL_VERSION}

# 设置时区（可选）
ENV TZ=Asia/Shanghai

# 复制自定义配置文件（可选）
COPY my.conf /etc/mysql/conf.d/my.conf

# 设置配置文件权限
RUN chmod 0444 /etc/mysql/conf.d/my.conf

# 针对 MySQL 8.0 的特殊配置
RUN if [ ${MYSQL_VERSION} = '8.0' ]; then \
    echo 'default-authentication-plugin=mysql_native_password' >> /etc/mysql/conf.d/my.cnf; \
  fi