#!/bin/bash

# Stop any existing container
docker stop beid-mw 2>/dev/null || true
docker rm beid-mw 2>/dev/null || true

# Build the image
docker build -t beid-mw:latest -f docker/Dockerfile .

# Run the container with proper device access
docker run -d \
  --name beid-mw \
  -p 8080:8080 \
  --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  --device-cgroup-rule='c 189:* rmw' \
  -v /run/pcscd:/run/pcscd \
  beid-mw:latest

# Print logs to check for issues
echo "Container started, printing logs:"
sleep 2
docker logs beid-mw

# Command to check environment variables
echo "To check environment variables inside the container:"
echo "docker exec beid-mw env | grep PYKCS11"

# Command to find smart card readers
echo "To check for smart card readers inside the container:"
echo "docker exec beid-mw find / -name \"libbeidpkcs11.so*\" 2>/dev/null"
echo "docker exec beid-mw ls -la /usr/lib/libbeidpkcs11.so.0 || ls -la /usr/lib/x86_64-linux-gnu/libbeidpkcs11.so.0"

# Print container status
echo "Container status:"
docker ps -a | grep beid-mw 