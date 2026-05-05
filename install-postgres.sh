#!/bin/bash

set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "📦 Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

echo "▶️ Starting PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Ask for admin credentials
read -p "Enter admin username: " ADMIN_USER
read -s -p "Enter admin password: " ADMIN_PASS
echo ""
read -s -p "Confirm admin password: " ADMIN_PASS_CONFIRM
echo ""

if [ "$ADMIN_PASS" != "$ADMIN_PASS_CONFIRM" ]; then
  echo "❌ Passwords do not match"
  exit 1
fi

echo "👤 Creating admin user with full privileges..."

sudo -u postgres psql <<EOF
CREATE USER $ADMIN_USER WITH PASSWORD '$ADMIN_PASS' SUPERUSER CREATEDB CREATEROLE LOGIN;
EOF

echo "🌐 Configuring PostgreSQL for remote access..."

PG_CONF=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW config_file;")
PG_HBA=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;")

# Allow listening on all IPs
sudo sed -i "s/^#listen_addresses =.*/listen_addresses = '*'/" $PG_CONF

# Allow admin user from anywhere (password auth)
echo "host    all             $ADMIN_USER        0.0.0.0/0            md5" | sudo tee -a $PG_HBA

echo "🔒 Ensuring postgres user is local-only (no password)..."
# Keep postgres using peer (local only)
echo "local   all             postgres                                peer" | sudo tee -a $PG_HBA

echo "🔄 Restarting PostgreSQL..."
sudo systemctl restart postgresql

echo ""
echo "✅ PostgreSQL setup complete!"
echo ""
echo "👤 Admin user:"
echo "Username: $ADMIN_USER"
echo "Password: (hidden)"
echo ""
echo "🌐 Remote access enabled for admin user"
echo "📍 Port: 5432"
echo ""
echo "🔐 postgres user:"
echo "- Local access only"
echo "- No password (peer auth)"
echo ""
echo "⚠️ IMPORTANT: Open firewall if needed:"
echo "sudo ufw allow 5432"
