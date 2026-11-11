#!/bin/sh
set -eu

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

if [ ! -f /var/www/html/index.php ]; then
    mkdir -p /var/www/html
    cp -a /usr/src/wordpress/. /var/www/html/
fi

chown -R www-data:www-data /var/www/html/wp-content

if [ ! -f /var/www/html/wp-config.php ]; then
   wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="$DB_HOST" \
        --path=/var/www/html \
        --allow-root

    chown root:www-data /var/www/html/wp-config.php
    chmod 640 /var/www/html/wp-config.php
fi

if ! wp core is-installed --path=/var/www/html --allow-root; then
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
fi

if ! wp user get wp_user --field=ID --path=/var/www/html --allow-root >/dev/null 2>&1; then
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=editor \
        --user_pass="$WP_USER_PASSWORD" \
        --path=/var/www/html \
        --allow-root
fi

exec php-fpm8.2 -F