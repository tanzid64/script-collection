#!/bin/bash

set -e

echo "Enter the domain for pgAdmin (e.g. pga.example.com):"
read DOMAIN

echo "Enter the local port for pgAdmin backend (default 5050):"
read APP_PORT
APP_PORT=${APP_PORT:-5050}

echo "Enter the initial pgAdmin login email:"
read PGADMIN_EMAIL

echo "Enter the initial pgAdmin login password:"
read -s PGADMIN_PASSWORD
echo ""
echo "Confirm password:"
read -s PGADMIN_PASSWORD_CONFIRM
echo ""

if [ "$PGADMIN_PASSWORD" != "$PGADMIN_PASSWORD_CONFIRM" ]; then
    echo "Error: Passwords do not match."
    exit 1
fi

NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
APP_DIR="/var/lib/pgadmin-app"
VENV_DIR="$APP_DIR/venv"

echo "Updating system packages..."
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip libpq-dev build-essential

echo "Creating pgAdmin app directory and virtualenv..."
sudo mkdir -p "$APP_DIR"
sudo python3 -m venv "$VENV_DIR"

echo "Installing pgAdmin4 + gunicorn via pip..."
sudo "$VENV_DIR/bin/pip" install --upgrade pip
sudo "$VENV_DIR/bin/pip" install pgadmin4 gunicorn

# Locate the installed pgadmin4 package dir (holds config + setup.py)
PGADMIN_PKG=$(sudo "$VENV_DIR/bin/python" -c "import os, pgadmin4; print(os.path.dirname(pgadmin4.__file__))")
echo "pgAdmin package: $PGADMIN_PKG"

echo "Writing pgAdmin config (data/log paths, server mode)..."
sudo tee "$PGADMIN_PKG/config_local.py" >/dev/null <<EOF
import os
DATA_DIR = '/var/lib/pgadmin'
LOG_FILE = '/var/log/pgadmin/pgadmin4.log'
SERVER_MODE = True
DEFAULT_SERVER = '127.0.0.1'
DEFAULT_SERVER_PORT = $APP_PORT
EOF

echo "Creating data/log dirs and dedicated user..."
sudo useradd -r -s /usr/sbin/nologin pgadmin 2>/dev/null || true
sudo mkdir -p /var/lib/pgadmin /var/log/pgadmin
sudo chown -R pgadmin:pgadmin /var/lib/pgadmin /var/log/pgadmin "$APP_DIR"

echo "Running pgAdmin initial setup (creating admin account)..."
sudo PGADMIN_SETUP_EMAIL="$PGADMIN_EMAIL" PGADMIN_SETUP_PASSWORD="$PGADMIN_PASSWORD" \
    runuser -u pgadmin -- "$VENV_DIR/bin/python" "$PGADMIN_PKG/setup.py" setup-db

echo "Creating systemd service..."
sudo tee /etc/systemd/system/pgadmin.service >/dev/null <<EOF
[Unit]
Description=pgAdmin 4 (gunicorn)
After=network.target

[Service]
User=pgadmin
Group=pgadmin
WorkingDirectory=$PGADMIN_PKG
ExecStart=$VENV_DIR/bin/gunicorn --bind 127.0.0.1:$APP_PORT --workers 1 --threads 25 pgAdmin4:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "Starting pgAdmin service..."
sudo systemctl daemon-reload
sudo systemctl enable pgadmin
sudo systemctl restart pgadmin

echo "Creating nginx config..."
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "Enabling site..."
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/"$DOMAIN"

echo "Testing nginx config..."
sudo nginx -t

echo "Reloading nginx..."
sudo systemctl reload nginx

echo ""
echo "pgAdmin installed successfully!"
echo "Visit: http://$DOMAIN"
echo ""
echo "Login email: $PGADMIN_EMAIL"
echo "Backend: 127.0.0.1:$APP_PORT (gunicorn, local only)"
echo ""
echo "TIP: add HTTPS with certbot --nginx -d $DOMAIN"
