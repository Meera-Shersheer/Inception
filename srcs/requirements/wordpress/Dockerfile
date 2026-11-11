FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    wget \
    php8.2-cli \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod 755 /usr/local/bin/wp

RUN mkdir -p /usr/src/wordpress && \
    wget -qO- https://wordpress.org/latest.tar.gz | tar -xz -C /tmp && \
    cp -a /tmp/wordpress/. /usr/src/wordpress/ && \
    rm -rf /tmp/wordpress

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/wordpress-entrypoint

RUN chmod 755 /usr/local/bin/wordpress-entrypoint && \
    mkdir -p /run/php /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wordpress-entrypoint"]




