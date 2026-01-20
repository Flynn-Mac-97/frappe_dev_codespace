#!/bin/bash

set -e

if [[ -f "/workspaces/frappe_codespace/frappe-bench/apps/frappe" ]]
then
    echo "Bench already exists, skipping init"
    exit 0
fi

rm -rf /workspaces/frappe_codespace/.git

source /home/frappe/.nvm/nvm.sh
nvm alias default 24
nvm use 24

echo "nvm use 24" >> ~/.bashrc
cd /workspace

# Set compatibility flag for Python 3.14
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1

bench init \
--ignore-exist \
--skip-redis-config-generation \
--frappe-branch version-15 \
--python python3 \
frappe-bench

cd frappe-bench

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis-cache:6379
bench set-redis-queue-host redis://redis-queue:6379
bench set-redis-socketio-host redis://redis-socketio:6379

# Remove redis from Procfile
sed -i '/redis/d' ./Procfile

# Get ERPNext version 15
bench get-app erpnext --branch version-15 https://github.com/frappe/erpnext.git

bench new-site dev.localhost \
--mariadb-root-password 123 \
--admin-password admin \
--no-mariadb-socket

# Install ERPNext on the site
bench --site dev.localhost install-app erpnext

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost
