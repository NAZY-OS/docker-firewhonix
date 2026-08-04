#!/bin/bash

read -p "Do you want to start the container interactively? (y/n): " response

# Definiere die Ports
EXTERNAL_PORT_4711=4711
EXTERNAL_PORTS_9051_9062="9051-9062"
EXTERNAL_PORT_9080=9080

#Create my_vlan
docker network create my_vlan 2> /dev/null

# Starte den Docker-Container
if [[ "$response" == "y" || "$response" == "Y" ]]; then
    docker run --rm -it \
        -p $EXTERNAL_PORT_4711:$EXTERNAL_PORT_4711 \
        -p $EXTERNAL_PORTS_9051_9062:$EXTERNAL_PORTS_9051_9062 \
        -p $EXTERNAL_PORT_9080:$EXTERNAL_PORT_9080 \
        --network my_vlan \
        firewhonix:1.2 /bin/sh -c "echo 'Container started' && ls -lha && sh -c 'start.sh &';bash"
else
    docker run --rm \
        -p $EXTERNAL_PORT_4711:$EXTERNAL_PORT_4711 \
        -p $EXTERNAL_PORTS_9051_9062:$EXTERNAL_PORTS_9051_9062 \
        -p $EXTERNAL_PORT_9080:$EXTERNAL_PORT_9080 \
        --network my_vlan \
        firewhonix:1.2 /bin/sh -c "echo 'Container started' && ls -lha && sh -c 'start.sh &';bash"
fi
