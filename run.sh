#!/bin/bash

VOLUME_NAMES=("frappe_sites_data" "frappe_assets_data" "frappe_logs_data" "frappe_mysql_data")

if [ "$1" == "remake" ]; then
    echo "Cleaning up old containers and images..."
    sudo docker system prune -f
    for VOLUME in "${VOLUME_NAMES[@]}"; do
        if sudo docker volume inspect "$VOLUME" > /dev/null 2>&1; then
            echo "Removing volume $VOLUME..."
            sudo docker volume rm "$VOLUME"
        else
            echo "Volume $VOLUME does not exist, skipping."
        fi
    done
fi

for VOLUME in "${VOLUME_NAMES[@]}"; do
    if sudo docker volume inspect "$VOLUME" > /dev/null 2>&1; then
        echo "Volume $VOLUME already exists."
    else
        echo "Creating volume $VOLUME..."
        sudo docker volume create "$VOLUME"
    fi
done

sudo docker build -t frappe_app_container:latest .

sudo docker run -it -p 8000:8000 -p 9000:9000 \
    -v frappe_sites_data:/home/frappeuser/erpnext-bench/sites \
    -v frappe_assets_data:/home/frappeuser/erpnext-bench/sites/assets \
    -v frappe_logs_data:/home/frappeuser/erpnext-bench/logs \
    -v frappe_mysql_data:/var/lib/mysql \
    frappe_app_container:latest

