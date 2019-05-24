# ---- Base Image ----
FROM php:7.1-fpm-alpine AS base
RUN mkdir -p /var/www/html
# Set working directory
WORKDIR /var/www/html

RUN apk --update add \
    build-base \
    autoconf \
    git \
    icu-dev \
    libzip-dev \
    zip

RUN docker-php-ext-install \
    intl \
    bcmath\
    opcache \
    pdo \
    pdo_mysql \
    zip

# Composer part
COPY --from=composer /usr/bin/composer /usr/bin/composer
ENV COMPOSER_MEMORY_LIMIT -1
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN composer global require hirak/prestissimo  --prefer-dist --no-progress --no-suggest --optimize-autoloader --no-interaction --no-plugins --no-scripts

# Run in production mode
ENV SYMFONY_ENV prod

# ---- Dependencies ----
FROM base AS dependencies
COPY composer.json .

# install vendors
RUN SYMFONY_ENV=prod composer update --prefer-dist --no-plugins --no-scripts --no-dev --no-autoloader

# ---- Release ----
FROM base AS release
EXPOSE 9000
USER www-data
