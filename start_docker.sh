#!/bin/bash

read -p "Do you want to start the container interactively? (y/n): " response

# Define ports explicitly (HOST:CONTAINER)
EXTERNAL_PORT_4711=4711

# SOCKS ports to match TOR_PORT_BASE=9061 and MAX_INSTANCES=12
# -> SOCKS = 9061..9072 (12 ports)
EXTERNAL_PORTS=(
  9061 9062 9063 9064 9065 9066
  9067 9068 9069 9070 9071 9072
)

EXTERNAL_PORT_9080=9080

# Start the Docker container
if [[ "$response" == "y" || "$response" == "Y" ]]; then
  # Interactive mode: map all ports individually
  docker run --rm -it \
    -p "$EXTERNAL_PORT_4711:$EXTERNAL_PORT_4711" \
    $(for port in "${EXTERNAL_PORTS[@]}"; do echo "-p $port:$port"; done) \
    -p "$EXTERNAL_PORT_9080:$EXTERNAL_PORT_9080" \
    --network host \
    firewhonix:1.2 /bin/sh -c "echo 'Container started' && ls -lha && sh -c 'start.sh &' ; bash"
else
  # Non-interactive mode: map all ports individually
  docker run --rm \
    -p "$EXTERNAL_PORT_4711:$EXTERNAL_PORT_4711" \
    $(for port in "${EXTERNAL_PORTS[@]}"; do echo "-p $port:$port"; done) \
    -p "$EXTERNAL_PORT_9080:$EXTERNAL_PORT_9080" \
    --network host \
    firewhonix:1.2 /bin/sh -c "echo 'Container started' && ls -lha && sh -c 'start.sh &' ; bash"
fi
