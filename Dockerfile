ARG PHP_VERSION=8.5

FROM debian:bookworm-slim AS downloader

ENV AGENDAV_VERSION=3.3.1

ADD https://github.com/agendav/agendav/releases/download/$AGENDAV_VERSION/agendav-$AGENDAV_VERSION.tar.gz /tmp/

RUN cd /tmp && \
    tar -xf agendav-$AGENDAV_VERSION.tar.gz -C /tmp && \
    mv /tmp/agendav-$AGENDAV_VERSION /tmp/agendav


FROM php:${PHP_VERSION}-apache-bookworm

LABEL maintainer="Ruslan Nagimov <nagimov@outlook.com>"

ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV TERM=xterm
ENV AGENDAV_TIMEZONE=UTC
ENV PHP_INI_DIR=/usr/local/etc/php

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-transport-https \
        ca-certificates && \
    chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions curl mbstring xml pdo_sqlite && \
    rm /usr/local/bin/install-php-extensions && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=downloader --chown=www-data:www-data /tmp/agendav /var/www/agendav

COPY agendav.conf /etc/apache2/sites-available/agendav.conf
COPY --chown=www-data:www-data settings.php /var/www/agendav/config/settings.php.template
COPY run.sh /usr/local/bin/run.sh

ADD https://curl.se/ca/cacert.pem /etc/ssl/certs/cacert.pem

RUN chmod 644 /etc/ssl/certs/cacert.pem && \
    chown -R www-data:www-data /var/www/agendav && \
    chown -R www-data:www-data /var/run/apache2 && \
    chmod 755 ${APACHE_LOG_DIR} && \
    chown -R www-data:www-data ${APACHE_LOG_DIR} && \
    cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini && \
    echo 'date.timezone = "AGENDAV_TIMEZONE"' > ${PHP_INI_DIR}/conf.d/zz-agendav.ini && \
    echo 'openssl.cafile = "/etc/ssl/certs/cacert.pem"' >> ${PHP_INI_DIR}/php.ini && \
    echo 'curl.cainfo = "/etc/ssl/certs/cacert.pem"' >> ${PHP_INI_DIR}/php.ini && \
    chown www-data:www-data ${PHP_INI_DIR}/conf.d/zz-agendav.ini && \
    mkdir -p /var/agendav && \
    mkdir -p /var/log/agendav && \
    touch /var/agendav/db.sqlite && \
    chown -R www-data:www-data /var/agendav && \
    chown -R www-data:www-data /var/log/agendav && \
    chmod 640 /var/agendav/db.sqlite && \
    chmod +x /usr/local/bin/run.sh && \
    a2ensite agendav.conf && \
    a2dissite 000-default && \
    a2enmod rewrite && \
    echo "Listen 8080" > /etc/apache2/ports.conf

RUN ln -sf /dev/stdout ${APACHE_LOG_DIR}/access.log \
    && ln -sf /dev/stderr ${APACHE_LOG_DIR}/error.log \
    && ln -sf /dev/stderr ${APACHE_LOG_DIR}/davi-error.log

EXPOSE 8080

USER www-data

ENTRYPOINT ["/usr/local/bin/run.sh"]

CMD ["apache2"]
