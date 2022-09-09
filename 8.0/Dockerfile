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
    php8 \
    php8-dev \
    php8-common \
    php8-gd \
    php8-xmlreader \
    php8-bcmath \
    php8-ctype \
    php8-curl \
    php8-exif \
    php8-iconv \
    php8-intl \
    php8-mbstring \
    php8-opcache \
    php8-openssl \
    php8-pcntl \
    php8-phar \
    php8-session \
    php8-xml \
    php8-xsl \
    php8-zip \
    php8-zlib \
    php8-dom \
    php8-fpm \
    php8-sodium \
    php8-pdo \
    php8-pdo_pgsql \
    php8-pgsql \
    php8-posix \
    php8-redis \
    php8-tokenizer \
    php8-fileinfo \
    # Iconv Fix
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted php8-pecl-apcu \
    && ln -s /usr/bin/php8 /usr/bin/php

ADD rootfs /

USER ${USER}

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["/usr/sbin/php-fpm8", "-R", "--nodaemonize"]

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
        shadow \
        php8-pear \
        supervisor \
        autoconf \
        git \
        curl \
        wget \
        make \
        zip \
        php8-xdebug \
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
