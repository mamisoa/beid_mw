#!/bin/bash

# Check if container is running
if [ ! "$(docker ps -q -f name=beid-mw)" ]; then
    echo "Container beid-mw is not running"
    exit 1
fi

# Run debug commands
echo "==== Docker Container Logs ===="
docker logs beid-mw

echo -e "\n==== Checking PCSCD Status ===="
docker exec beid-mw ps aux | grep pcscd

echo -e "\n==== Environment Variables ===="
docker exec beid-mw env | grep PYKCS11

echo -e "\n==== Checking PKCS11 Library ===="
docker exec beid-mw bash -c 'ls -la $PYKCS11LIB 2>/dev/null || echo "Library not found at $PYKCS11LIB"'
docker exec beid-mw find / -name "libbeidpkcs11.so*" 2>/dev/null

echo -e "\n==== Check Python Library Import ===="
docker exec -it beid-mw python3 -c "try: from PyKCS11 import PyKCS11; print('PyKCS11 imported successfully'); except Exception as e: print(f'Error importing PyKCS11: {str(e)}')"

echo -e "\n==== USB Devices ===="
docker exec beid-mw lsusb

echo -e "\n==== Smart Card Readers ===="
docker exec beid-mw pcsc_scan -n

echo -e "\n==== Testing API Request ===="
docker exec beid-mw curl -v http://localhost:8080/

echo -e "\n==== Application Logs ===="
docker exec beid-mw bash -c 'find / -name "beid_mw_*.log" -type f 2>/dev/null | xargs cat 2>/dev/null || echo "No log files found"'

echo -e "\n==== Debugging completed ====" 