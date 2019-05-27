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
COPY composer.lock .

# install vendors
RUN SYMFONY_ENV=prod composer install --prefer-dist --no-plugins --no-scripts --no-dev --no-autoloader

# ---- Release ----
FROM base AS release
EXPOSE 9000
USER www-data
COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data --from=dependencies /var/www/html/vendor /var/www/html/vendor
RUN composer dump-autoload
RUN php bin/console assets:install public
RUN php bin/console c:c -e ${SYMFONY_ENV} && bin/console c:w -e ${SYMFONY_ENV}
CMD ["php-fpm"]
