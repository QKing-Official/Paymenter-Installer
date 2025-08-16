#!/bin/bash
set -e

echo "=== Paymenter Installation Script ==="

# Ask user for inputs
read -p "Enter your Paymenter database username [paymenter]: " DB_USER
DB_USER=${DB_USER:-paymenter}

read -s -p "Enter your Paymenter database password: " DB_PASS
echo
read -p "Enter your Paymenter database name [paymenter]: " DB_NAME
DB_NAME=${DB_NAME:-paymenter}

read -p "Enter your Paymenter domain (example.com): " APP_URL

# Update system and install dependencies
echo "Installing dependencies..."
apt update
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg tar unzip git redis-server

# PHP 8.3 repository
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

# MariaDB repository
curl -sSL https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version="mariadb-10.11"

apt update
apt -y install php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} mariadb-server nginx

# Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create Paymenter directory
echo "Creating Paymenter directory..."
mkdir -p /var/www/paymenter
cd /var/www/paymenter

# Download and extract latest Paymenter release
echo "Downloading Paymenter..."
curl -Lo paymenter.tar.gz https://github.com/paymenter/paymenter/releases/latest/download/paymenter.tar.gz
tar -xzvf paymenter.tar.gz

# Set folder permissions
chmod -R 755 storage/* bootstrap/cache/

# Install composer packages
composer install --no-dev --optimize-autoloader

# Setup database
echo "Setting up database..."
mysql -u root <<MYSQL_SCRIPT
CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
CREATE DATABASE IF NOT EXISTS $DB_NAME;
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Setup .env
cp .env.example .env
php artisan key:generate --force
php artisan storage:link

# Update .env with user info
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env

# Setup database tables and seed
php artisan migrate --force --seed
php artisan app:init
php artisan app:user:create

# Setup cronjob
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/paymenter/artisan schedule:run >> /dev/null 2>&1") | crontab -

# Setup queue worker service
echo "Creating Paymenter queue worker service..."
cat <<EOF >/etc/systemd/system/paymenter.service
[Unit]
Description=Paymenter Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/paymenter/artisan queue:work
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now paymenter.service
systemctl enable --now redis-server

# Nginx setup
echo "Setting up Nginx configuration..."
cat <<EOF >/etc/nginx/sites-available/paymenter.conf
server {
    listen 80;
    listen [::]:80;
    server_name $APP_URL;
    root /var/www/paymenter/public;

    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }
}
EOF

ln -s /etc/nginx/sites-available/paymenter.conf /etc/nginx/sites-enabled/
systemctl restart nginx

# Set correct permissions
chown -R www-data:www-data /var/www/paymenter/*

echo "=== Installation Complete! ==="
echo "Visit your app at http://$APP_URL"
