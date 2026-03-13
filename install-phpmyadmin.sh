#!/bin/bash

set -e

echo "Enter the domain for phpMyAdmin (e.g. pma.example.com):"
read DOMAIN

echo "Enter the web root path (e.g. /var/www/phpmyadmin):"
read WEB_ROOT

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

echo "Detecting PHP-FPM socket..."
PHP_SOCK=$(ls /run/php/php*-fpm.sock | head -n 1)

if [ -z "$PHP_SOCK" ]; then
    echo "PHP-FPM socket not found. Exiting."
    exit 1
fi

echo "Using PHP socket: $PHP_SOCK"

echo "Downloading phpMyAdmin..."
cd /tmp
rm -rf phpMyAdmin*
wget -q https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
unzip -q phpMyAdmin-latest-all-languages.zip

PMA_DIR=$(find . -maxdepth 1 -type d -name "phpMyAdmin-*")

echo "Moving files to $WEB_ROOT..."
rm -rf "$WEB_ROOT"
mkdir -p "$WEB_ROOT"
mv "$PMA_DIR"/* "$WEB_ROOT"

echo "Setting permissions..."
chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

echo "Creating nginx config..."

cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $WEB_ROOT;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

echo "Enabling site..."
ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/"$DOMAIN"

echo "Testing nginx config..."
nginx -t

echo "Reloading nginx..."
systemctl reload nginx

echo "phpMyAdmin installed successfully!"
echo "Visit: http://$DOMAIN"
