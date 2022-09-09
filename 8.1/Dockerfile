# **************
# * User args *
# **************
ARG USER=non-root
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# **************
# * Main image *
# **************
FROM alpine:3.16 as main

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
    --home "/home/${USER}" \
    --ingroup ${USER} \
    ${USER} \
    && apk --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/main add \
    icu-libs \
    icu-data-full \
    && apk --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/edge/community add \
    # Current packages don't exist in other repositories
    libavif \
    && apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ --allow-untrusted gnu-libiconv \
    # Packages
    tini \
    fcgi \
    php81 \
    php81-dev \
    php81-common \
    php81-gd \
    php81-xmlreader \
    php81-bcmath \
    php81-ctype \
    php81-curl \
    php81-exif \
    php81-iconv \
    php81-intl \
    php81-mbstring \
    php81-opcache \
    php81-openssl \
    php81-pcntl \
    php81-phar \
    php81-session \
    php81-xml \
    php81-xsl \
    php81-zip \
    php81-zlib \
    php81-dom \
    php81-fpm \
    php81-sodium \
    php81-pdo \
    php81-pdo_pgsql \
    php81-pgsql \
    php81-posix \
    php81-redis \
    php81-tokenizer \
    php81-fileinfo \
    # Iconv Fix
    php81-pecl-apcu \
    && ln -s /usr/bin/php81 /usr/bin/php

ADD rootfs /

USER ${USER}

ENTRYPOINT ["/sbin/tini", "--"]

CMD ["/usr/sbin/php-fpm81", "-R", "--nodaemonize"]

EXPOSE 9000

WORKDIR /var/www/app

# *************
# * Dev image *
# *************
FROM main as dev

ARG USER
ARG COMPOSER_VERSION=2.4.1

USER root

RUN apk add -U --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/   \
        shadow \
        php81-pear \
        supervisor \
        autoconf \
        git \
        curl \
        wget \
        make \
        zip \
        php81-xdebug \
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
