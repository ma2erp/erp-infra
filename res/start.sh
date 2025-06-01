#!/bin/bash

set -e

echo "Starting the MariaDB service..."
sudo service mariadb start

echo "Waiting for MariaDB to be ready..."
until mysqladmin ping -hlocalhost --silent; do
    echo -n "."
    sleep 1
done
echo "MariaDB is up!"

echo "Starting Redis..."
sudo service redis-server start

# Wait for Redis to be available (simple check for port 6379)
echo "Waiting for Redis to be ready..."
until nc -z localhost 6379; do
    echo -n "."
    sleep 1
done
echo "Redis is up!"

echo "Starting Frappe Bench..."
cd /home/frappeuser/erpnext-bench && exec bench start
