#!/bin/bash

# Prompt: Enable interactive mode?
read -p "Start container interactively? (y/n) [Enter = n]: " response

# Create Docker network if it doesn't exist
#docker network create mynet 2>/dev/null || true

# Default: Non-interactive mode (if Enter is pressed)
response=${response:-n}

# Define ports explicitly (HOST:CONTAINER)
EXTERNAL_PORT_4711=4711

# Start the Docker container
if [[ "$response" =~ ^[yY](es)?$ ]]; then
    # Interactive mode
    echo "Starting container in INTERACTIVE MODE..."
    docker run --rm -it \
        -p "$EXTERNAL_PORT_4711:$EXTERNAL_PORT_4711" \
        --network host \
        firewhonix:1.2 /bin/sh -c "echo 'Container started' && sh -c 'bash -xv /sbin/start.sh &'; bash"
else
    # Non-interactive mode
    echo "Starting container in NON-INTERACTIVE MODE..."
    docker run --rm -it \
        -p "$EXTERNAL_PORT_4711:$EXTERNAL_PORT_4711" \
        --network host \
        firewhonix:1.2 /bin/sh -c "echo 'Container started' && sh -c '/sbin/start.sh &'; bash"
fi
