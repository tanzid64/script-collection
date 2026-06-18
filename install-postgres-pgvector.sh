#!/bin/bash

set -e

echo "=========================================="
echo "   PostgreSQL + pgvector Installation"
echo "=========================================="

# Step 1: Install PostgreSQL Server
echo ""
echo "Updating system packages..."
sudo apt update -y

echo ""
echo "Installing PostgreSQL Server (latest available)..."
sudo apt install -y postgresql postgresql-contrib

# Step 2: Enable and Start PostgreSQL
echo ""
echo "Starting PostgreSQL service..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Step 3: Install pgvector extension
echo ""
echo "Installing pgvector (vector embeddings) extension..."

# Detect installed PostgreSQL major version
PG_VERSION=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW server_version_num;")
PG_MAJOR=$((PG_VERSION / 10000))

echo "Detected PostgreSQL major version: ${PG_MAJOR}"

# Install matching pgvector package; fall back to building from source if unavailable
if sudo apt install -y "postgresql-${PG_MAJOR}-pgvector"; then
    echo "Installed pgvector from apt."
else
    echo "apt package not found, building pgvector from source..."
    sudo apt install -y git make gcc "postgresql-server-dev-${PG_MAJOR}"
    TMP_DIR=$(mktemp -d)
    git clone --branch v0.8.0 https://github.com/pgvector/pgvector.git "$TMP_DIR/pgvector"
    make -C "$TMP_DIR/pgvector"
    sudo make -C "$TMP_DIR/pgvector" install
    rm -rf "$TMP_DIR"
fi

# Step 4: Ask for Admin Credentials
echo ""
echo "=========================================="
echo "Create PostgreSQL Admin User"
echo "=========================================="

read -p "Enter admin username: " ADMIN_USER
read -s -p "Enter admin password: " ADMIN_PASS
echo ""
read -s -p "Confirm admin password: " ADMIN_PASS_CONFIRM
echo ""

if [ "$ADMIN_PASS" != "$ADMIN_PASS_CONFIRM" ]; then
    echo "Error: Passwords do not match."
    exit 1
fi

# Step 5: Create Admin User with Full Privileges + Enable vector extension
echo ""
echo "Creating admin user and enabling vector extension..."

sudo -u postgres psql <<EOF
CREATE USER $ADMIN_USER WITH PASSWORD '$ADMIN_PASS' SUPERUSER CREATEDB CREATEROLE LOGIN;
CREATE EXTENSION IF NOT EXISTS vector;
EOF

echo ""
echo "Note: 'vector' extension enabled on the default 'postgres' database."
echo "Run 'CREATE EXTENSION IF NOT EXISTS vector;' inside each new database that needs it."

# Step 6: Allow Remote Connections
echo ""
echo "Configuring PostgreSQL for remote access..."

PG_CONF=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW config_file;")
PG_HBA=$(sudo -u postgres psql -t -P format=unaligned -c "SHOW hba_file;")

# Allow listening on all IPs
sudo sed -i "s/^#listen_addresses =.*/listen_addresses = '*'/" "$PG_CONF"

# Allow admin user from anywhere (password auth)
echo "host    all             $ADMIN_USER        0.0.0.0/0            md5" | sudo tee -a "$PG_HBA"

echo "Ensuring postgres user is local-only (no password)..."
echo "local   all             postgres                                peer" | sudo tee -a "$PG_HBA"

# Step 7: Restart PostgreSQL
echo ""
echo "Restarting PostgreSQL..."
sudo systemctl restart postgresql

echo ""
echo "=========================================="
echo " PostgreSQL + pgvector Setup Complete"
echo "=========================================="

echo ""
echo "PostgreSQL Version:"
psql --version

echo ""
echo "pgvector extension installed and enabled."

echo ""
echo "Admin User Created:"
echo "Username: $ADMIN_USER"
echo "Password: (hidden)"
echo "Privileges: SUPERUSER (full access)"

echo ""
echo "Remote access enabled for admin user"
echo "Port: 5432"
echo ""
echo "postgres user: local access only (peer auth, no password)"
echo ""
echo "You can connect using:"
echo "psql -U $ADMIN_USER -h YOUR_SERVER_IP -d postgres"
echo ""
echo "Test vector support:"
echo "  CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));"
echo "  INSERT INTO items (embedding) VALUES ('[1,2,3]');"
echo "  SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 1;"
echo ""
echo "IMPORTANT: Open firewall if needed:"
echo "sudo ufw allow 5432"
