#!/bin/bash

echo
echo Rebuilding docker in 3 sec
echo
echo
sleep 3

bash remove_docker.sh || ( echo "Error Failed " && exit )
bash build_docker.sh || ( echo "Error Failed " && exit )

echo
echo
echo Rebuild completed
echo
echo Done!
echo
echo Run docker in 2 seconds!
sleep 2

bash run-docker.sh || ( echo "Error Failed " && exit )
