# =============================================================================
# MensWear / Bagisto — lightweight image for Render free tier (512 MB RAM)
# Database: external PostgreSQL (Neon free tier recommended)
# =============================================================================

# --- Stage 1: Build storefront assets ----------------------------------------
FROM node:22-bookworm-slim AS assets

WORKDIR /build

COPY packages/Webkul/Shop/package.json packages/Webkul/Shop/package-lock.json ./packages/Webkul/Shop/

RUN cd packages/Webkul/Shop && npm ci

COPY packages/Webkul/Shop ./packages/Webkul/Shop

RUN cd packages/Webkul/Shop && npm run build


# --- Stage 2: Install PHP dependencies ---------------------------------------
FROM php:8.3-cli-bookworm AS vendor

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        unzip \
        libicu-dev \
        libzip-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libgmp-dev \
        libpq-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) bcmath calendar gd gmp intl mbstring pdo_mysql pdo_pgsql zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY . .

RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts


# --- Stage 3: Production runtime ---------------------------------------------
FROM php:8.3-fpm-bookworm

ENV APP_ENV=production
ENV APP_DEBUG=false
ENV LOG_CHANNEL=stderr
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        gettext-base \
        libfreetype6-dev \
        libgmp-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        nginx \
        supervisor \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        calendar \
        exif \
        gd \
        gmp \
        intl \
        mbstring \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        zip \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/* /tmp/*

COPY docker/render/php.ini /usr/local/etc/php/conf.d/99-bagisto.ini

RUN sed -i 's/pm.max_children = 5/pm.max_children = 3/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/pm.start_servers = 2/pm.start_servers = 1/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 2/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/;clear_env = no/clear_env = no/' /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html

COPY --from=vendor /app /var/www/html
COPY --from=assets /build/public/themes /var/www/html/public/themes

COPY docker/render/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY docker/render/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/render/start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh \
    && rm -f /etc/nginx/sites-enabled/default \
    && mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 10000

CMD ["/usr/local/bin/start.sh"]
