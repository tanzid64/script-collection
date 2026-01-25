#!/bin/bash

set -e

echo "=========================================="
echo "   MySQL Latest Installation + Admin User"
echo "=========================================="

# Step 1: Install MySQL Server
echo ""
echo "Updating system packages..."
sudo apt update -y

echo ""
echo "Installing MySQL Server (latest available)..."
sudo apt install mysql-server -y

# Step 2: Enable and Start MySQL
echo ""
echo "Starting MySQL service..."
sudo systemctl enable mysql
sudo systemctl start mysql

# Step 3: Ask for Admin Password
echo ""
echo "=========================================="
echo "Create MySQL Admin User"
echo "=========================================="

read -s -p "Enter password for MySQL admin user: " ADMIN_PASS
echo ""
read -s -p "Confirm password: " ADMIN_PASS_CONFIRM
echo ""

if [ "$ADMIN_PASS" != "$ADMIN_PASS_CONFIRM" ]; then
    echo "Error: Passwords do not match."
    exit 1
fi

# Step 4: Create Admin User with Full Privileges
echo ""
echo "Creating MySQL user 'admin' with full privileges..."

sudo mysql <<EOF
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY '${ADMIN_PASS}';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Step 5: Allow Remote Connections (Bind Address Update)
echo ""
echo "Configuring MySQL to allow remote access..."

MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"

sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" $MYSQL_CONF

# Restart MySQL after config change
sudo systemctl restart mysql

echo ""
echo "=========================================="
echo " MySQL Installation & Admin Setup Complete"
echo "=========================================="

echo ""
echo "MySQL Version:"
mysql --version

echo ""
echo "Admin User Created:"
echo "Username: admin"
echo "Host: % (any domain/IP)"
echo "Privileges: FULL ROOT ACCESS"

echo ""
echo "You can connect using:"
echo "mysql -u admin -p -h YOUR_SERVER_IP"
echo ""
