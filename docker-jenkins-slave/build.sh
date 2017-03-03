#!/bin/bash

# Script used to build docker jenkins slaves

# Build puppetunit image
echo "Building puppetunit image..."
docker build -t puppetunit --build-arg ROLE=puppetunit .

# Build puppetci image
#echo "Building puppetci image..."
#docker build -t puppetci --build-arg ROLE=puppetci .

echo "Image builds complete"
