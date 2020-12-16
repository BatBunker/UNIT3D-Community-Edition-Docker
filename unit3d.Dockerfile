FROM php:7.4-fpm
ENV TZ America/Edmonton
RUN apt-get update && apt-get install -y \
        libzip-dev \
        libsodium-dev \
        libicu-dev \
        unzip \
        libmariadb-dev-compat libmariadb-dev \
        mariadb-client \
        libcurl4-openssl-dev libssl-dev cron \
    && docker-php-ext-configure pdo_mysql \
    && docker-php-ext-install -j$(nproc) zip bcmath intl pdo_mysql
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis
VOLUME ["/app/static", "/app/files", "/app/storage", "/app/vendor"]
WORKDIR /app
RUN apt update && apt install wget -y
RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
COPY unit3d.ini /usr/local/etc/php/conf.d/unit3d.ini
COPY scripts/configure_docker.sh ./
COPY src/composer.json src/composer.lock src/composer-setup.sh src/preload.php ./
COPY scripts/unit3d.cron /etc/cron.d/unit3d.cron
RUN crontab /etc/cron.d/unit3d.cron
RUN touch /var/log/cron.log
COPY scripts/docker_setup.sh .
COPY src/grumphp.yml .
RUN mkdir -p public
COPY ./src/artisan .
COPY ./src/app/ app/
COPY ./src/bootstrap/ bootstrap/
COPY ./src/database/ database/
COPY ./src/config/ config/
COPY ./src/routes/ routes/
COPY ./src/resources/ resources/
RUN ./composer-setup.sh
