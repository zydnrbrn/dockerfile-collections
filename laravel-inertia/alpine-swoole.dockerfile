FROM php:8.3-fpm-alpine

ENV PHP_INI_DIR=/usr/local/etc/php
ENV PATH="/root/.npm-global/bin:${PATH}"

RUN apk update && \
    apk add --no-cache \
    nginx \
    curl \
    unzip \
    supervisor \
    nano \
    openssl \
    gcc \
    g++ \
    make \
    autoconf \
    bash \
    libxml2-dev \
    oniguruma-dev \
    zlib-dev \
    brotli-dev \
    && pecl install swoole \
    && docker-php-ext-enable swoole \
    && docker-php-ext-install pdo_mysql pcntl

RUN apk add --no-cache nodejs npm

WORKDIR /var/www/html

COPY . /var/www/html

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install && composer dump-autoload --optimize

RUN npm install && npm run build

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

RUN [ ! -f /etc/nginx/nginx.conf ] || rm /etc/nginx/nginx.conf

COPY alpine-swoole-conf/nginx/nginx.conf /etc/nginx/nginx.conf

COPY alpine-swoole-conf/nginx/default.conf /etc/nginx/conf.d/default.conf

COPY alpine-swoole-conf/supervisord.conf /etc/supervisord.conf

RUN mkdir -p /var/log/supervisor && chown -R www-data:www-data /var/log/supervisor

EXPOSE 8000

CMD ["sh", "-c", "supervisord -c /etc/supervisord.conf"]

