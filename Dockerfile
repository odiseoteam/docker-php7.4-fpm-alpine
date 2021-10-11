FROM php:7.4-fpm-alpine3.13

# Add dependencies
RUN apk add --update --no-cache --virtual .dd-build-deps python2 oniguruma-dev zlib-dev libzip-dev libpng-dev libwebp-dev libjpeg-turbo-dev freetype-dev libgd libzip libpng libjpeg libpq libxml2 libxml2-dev $PHPIZE_DEPS
RUN ln -sf python2 /usr/bin/python

RUN apk add acl

# Install GD
RUN docker-php-ext-configure gd --with-webp --with-jpeg \
  && docker-php-ext-install -j "$(nproc)" gd

# Add php-apc support
RUN pecl install apcu \
  && pecl install apcu_bc-1.0.5 \
  && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
  && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

# Install php libraries
RUN docker-php-ext-install sockets exif opcache xml soap mbstring pdo_mysql zip \
  && docker-php-ext-install bcmath

# Clear
RUN pecl clear-cache

# Install intl extension
RUN apk add --no-cache \
  icu-dev \
  && docker-php-ext-install -j$(nproc) intl \
  && docker-php-ext-enable intl \
  && rm -rf /tmp/*

# fix work iconv library with alphine
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Add Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER=1
# TODO Delete this after updates packages to support composer 2
RUN composer self-update --1

# Add NodeJS NPM Yarn
RUN apk add nodejs npm yarn