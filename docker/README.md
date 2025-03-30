# Belgian eID Middleware Docker Container

This Docker image provides a lightweight container for running the Belgian eID middleware FastAPI application.

## Building and Running with Docker Compose (Recommended)

The simplest way to run the container:

```bash
cd docker
docker-compose up -d
```

This will:
1. Build the Docker image
2. Start the container with all necessary configurations
3. Make the API accessible at http://localhost:8080

To stop the container:
```bash
docker-compose down
```

## Manual Building and Running

```bash
docker build -t beid-mw:latest -f docker/Dockerfile .
```

## Running the Container

Basic usage:
```bash
docker run -d -p 8080:8080 --name beid-mw beid-mw:latest
```

For smart card access, you need to connect the container to your USB devices. There are two options:

### Option 1: Using `--privileged` (Not recommended for production)

```bash
docker run -d \
  --name beid-mw \
  -p 8080:8080 \
  --privileged \
  beid-mw:latest
```

### Option 2: Mounting specific devices (Recommended)

```bash
docker run -d \
  --name beid-mw \
  -p 8080:8080 \
  --device /dev/bus/usb \
  beid-mw:latest
```

You may need to adjust the device path depending on your system.

## Checking Container Status

```bash
docker ps -a | grep beid-mw
docker logs beid-mw
```

## Accessing the API

The API will be accessible at:
```
http://localhost:8080
```

## Troubleshooting

If you encounter issues with smart card access:

1. Make sure your smart card reader is properly connected to your host
2. Check if pcscd is running on your host: `systemctl status pcscd`
3. Inspect the container logs: `docker logs beid-mw`

### Debugging Tools

The container includes several debugging tools to help diagnose issues:

1. Use the debug script for comprehensive diagnostics:
   ```bash
   ./docker/debug.sh
   ```
   This script will collect and display:
   - Container logs
   - PCSCD service status
   - Environment variables
   - PKCS11 library location
   - Connected USB devices
   - Detected smart card readers
   - Application logs

2. Access detailed logs:
   - Container logs: `docker logs beid-mw`
   - Application logs: `docker exec beid-mw cat /app/beid_mw_*.log`

3. Check for card readers:
   ```bash
   docker exec -it beid-mw pcsc_scan
   ```
   (Press CTRL+C to exit)

4. Check USB devices:
   ```bash
   docker exec beid-mw lsusb
   ```

5. Manually test the API:
   ```bash
   curl http://localhost:8080/
   ```

### Common Issues and Solutions

1. **"Could not find any reader with a card inserted"**
   - Verify your card reader is connected
   - Ensure the container has access to USB devices
   - Check if pcscd is running inside the container
   - Verify the PKCS11 library is correctly detected

2. **PCSCD service not running**
   - Restart the container
   - Ensure pcscd is installed on the host
   - Try running with `--privileged` flag for debugging

3. **PKCS11 library not found**
   - Check if eid-mw was installed correctly
   - Verify library path with: `docker exec beid-mw find / -name "libbeidpkcs11.so*"` 