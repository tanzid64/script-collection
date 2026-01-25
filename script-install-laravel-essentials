#!/bin/bash

set -e

echo "=========================================="
echo " Laravel PHP + Essentials Installer Script"
echo "=========================================="

# Ask user for PHP version
read -p "Enter PHP version you want to install (e.g. 8.1, 8.2, 8.3): " PHP_VERSION

echo ""
echo "Installing PHP $PHP_VERSION and Laravel essentials..."
echo ""

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y software-properties-common apt-transport-https ca-certificates lsb-release curl unzip git

# Add Ondrej PHP repository
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install PHP + Required Laravel Extensions
sudo apt install -y \
php${PHP_VERSION} \
php${PHP_VERSION}-cli \
php${PHP_VERSION}-fpm \
php${PHP_VERSION}-common \
php${PHP_VERSION}-mysql \
php${PHP_VERSION}-pgsql \
php${PHP_VERSION}-sqlite3 \
php${PHP_VERSION}-mbstring \
php${PHP_VERSION}-xml \
php${PHP_VERSION}-curl \
php${PHP_VERSION}-zip \
php${PHP_VERSION}-bcmath \
php${PHP_VERSION}-intl \
php${PHP_VERSION}-gd \
php${PHP_VERSION}-redis \
php${PHP_VERSION}-soap \
php${PHP_VERSION}-readline

# Set selected PHP version as default
sudo update-alternatives --set php /usr/bin/php${PHP_VERSION}

# Restart PHP-FPM
sudo systemctl restart php${PHP_VERSION}-fpm || true

# Install Composer
echo ""
echo "Installing Composer..."
echo ""

curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Verify installations
echo ""
echo "=========================================="
echo " Installation Completed Successfully!"
echo "=========================================="

echo ""
echo "Installed Versions:"
php -v
composer -V

echo ""
echo "Laravel Essentials Installed:"
echo "✔ PHP $PHP_VERSION"
echo "✔ Extensions (mbstring, xml, curl, zip, bcmath, intl, gd, mysql, etc.)"
echo "✔ Composer"
echo "✔ Git, Curl, Zip tools"
echo ""
echo "You can now run: composer create-project laravel/laravel myapp"
