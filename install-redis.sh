#!/bin/bash

set -e

echo "=========================================="
echo "   Redis Installation + Password Security"
echo "=========================================="

# Step 1: Update system
echo ""
echo "Updating system packages..."
sudo apt update -y

# Step 2: Install Redis
echo ""
echo "Installing Redis server (latest available)..."
sudo apt install redis-server -y

# Step 3: Enable Redis service
echo ""
echo "Enabling and starting Redis service..."
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Step 4: Ask for Redis Password
echo ""
echo "=========================================="
echo "Configure Redis Password"
echo "=========================================="

read -s -p "Enter password for Redis: " REDIS_PASS
echo ""
read -s -p "Confirm password: " REDIS_PASS_CONFIRM
echo ""

if [ "$REDIS_PASS" != "$REDIS_PASS_CONFIRM" ]; then
    echo "Error: Passwords do not match."
    exit 1
fi

# Step 5: Configure Redis Authentication
echo ""
echo "Configuring Redis password authentication..."

REDIS_CONF="/etc/redis/redis.conf"

# Backup original config
sudo cp $REDIS_CONF ${REDIS_CONF}.backup

# Set requirepass in redis.conf
sudo sed -i "s/^# requirepass.*/requirepass ${REDIS_PASS}/" $REDIS_CONF
sudo sed -i "s/^requirepass.*/requirepass ${REDIS_PASS}/" $REDIS_CONF

# Step 6: Restart Redis
echo ""
echo "Restarting Redis server..."
sudo systemctl restart redis-server

# Step 7: Verify Redis Status
echo ""
echo "Checking Redis service status..."
sudo systemctl status redis-server --no-pager

echo ""
echo "=========================================="
echo " Redis Installation & Security Complete"
echo "=========================================="

echo ""
echo "Redis is now protected with a password."
echo ""
echo "To connect locally:"
echo "redis-cli"
echo "AUTH your_password"
echo ""
echo "Or directly:"
echo "redis-cli -a your_password"
echo ""
