#!/bin/bash

CONTAINER=firewhonix:1.1

# Stop the container
echo "Stopping container: $CONTAINER"
docker stop "$CONTAINER"


# Restart Docker service
echo "Restarting Docker service..."
systemctl restart docker

# Check status
if systemctl is-active --quiet docker; then
    echo "Docker service restarted successfully."
else
    echo "Failed to restart Docker service."
    exit 1
fi
