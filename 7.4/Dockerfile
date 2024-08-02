# **************
# * User args *
# **************
ARG USER=non-root
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# **************
# * Main image *
# **************
FROM alpine:3.14 as main

LABEL maintainer="Egor Cherepovich <slymuzzle@gmail.com>"

ARG USER
ARG USER_UID
ARG USER_GID

# Path for php-fpm-healthcheck script
ENV FCGI_STATUS_PATH=/fpm_status

# Create group
RUN addgroup \
    --gid ${USER_GID} \
    ${USER} \
    # Create user
    && adduser \
    --uid ${USER_UID} \
    --disabled-password \
    --gecos "" \
    --ingroup ${USER} \
    --no-create-home \
    ${USER} \
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv \
    && apk add -U --no-cache \
    # Packages
    tini \
    fcgi \
    php7 \
    php7-amqp \
    php7-dev \
    php7-common \
    php7-apcu \
    php7-gd \
    php7-xmlreader \
    php7-xmlwriter \
    php7-bcmath \
    php7-ctype \
    php7-curl \
    php7-exif \
    php7-iconv \
    php7-intl \
    php7-json \
    php7-mbstring \
    php7-opcache \
    php7-openssl \
    php7-pcntl \
    php7-pdo \
    php7-mysqlnd \
    php7-pdo_mysql \
    php7-pdo_pgsql \
    php7-phar \
    php7-posix \
    php7-session \
    php7-xml \
    php7-xsl \
    php7-zip \
    php7-zlib \
    php7-dom \
    php7-redis \
    php7-fpm \
    php7-sodium \
    php7-pdo \
    php7-pdo_sqlite \
    php7-sqlite3 \
    php7-pdo_pgsql \
    php7-pgsql \
    php7-posix \
    php7-redis \
    php7-tokenizer \
    php7-fileinfo \
    php7-sqlite3

# iconv hack https://github.com/docker-library/php/issues/240
ENV LD_PRELOAD="/usr/lib/preloadable_libiconv.so php"

ADD rootfs /

USER ${USER}

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["/usr/sbin/php-fpm7", "-R", "--nodaemonize"]

EXPOSE 9000

WORKDIR /var/www/app

# *************
# * Dev image *
# *************
FROM main as dev

USER root

ARG USER
ARG COMPOSER_VERSION=2.4.1

RUN apk add -U --no-cache \
        bash \
        nodejs \
        yarn \
        shadow \
        php7-pear \
        supervisor \
        autoconf \
        git \
        curl \
        wget \
        make \
        zip \
        php7-xdebug \
    # Create folder for supervisord pid-file
    && mkdir /var/run/supervisord \
    && chown ${USER}:${USER} /var/run/supervisord \
    # Delete APK cache.
    && rm -rf /var/cache/apk/* \
    # Download composer.
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION}

ADD devfs /

ARG USER

USER ${USER}

CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord/conf.d/supervisord.conf"]

EXPOSE 22 9003
