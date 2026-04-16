#!/bin/bash

CONTAINER=firewhonix:1.1

# Remove all Docker containers
docker rm -f ${CONTAINER}

# Remove all Docker images
docker rmi -f ${CONTAINER}

echo "All Docker containers and images have been removed."
