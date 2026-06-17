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
3. Make the API accessible at http://localhost:8099

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
docker run -d -p 8099:8099 --name beid-mw beid-mw:latest
```

For smart card access, you need to connect the container to your USB devices. There are two options:

### Option 1: Using `--privileged` (Not recommended for production)

```bash
docker run -d \
  --name beid-mw \
  -p 8099:8099 \
  --privileged \
  beid-mw:latest
```

### Option 2: Mounting specific devices (Recommended)

```bash
docker run -d \
  --name beid-mw \
  -p 8099:8099 \
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
http://localhost:8099
```

## Platform Support (Linux only)

This image is **Linux-only** in practice. Although the production image is
self-contained (it ships and starts its own `pcscd`), it still needs raw access
to the **physical USB card reader**, which it gets through Linux USB passthrough:

```bash
--privileged
-v /dev/bus/usb:/dev/bus/usb
--device-cgroup-rule='c 189:* rmw'
```

### Why it does not work on Windows

On Windows, Docker Desktop runs containers inside a **Linux VM (WSL2/Hyper-V)**,
not directly on the host. As a result:

1. `/dev/bus/usb` **does not exist** on the Windows host, so the bind mount is
   empty or fails.
2. Docker Desktop on Windows **does not support native USB passthrough** nor
   `--privileged` device access for USB peripherals.
3. The container's `pcscd` therefore starts but sees **no reader**, and `/beid`
   returns "no reader / no card".

This is a limitation of Docker Desktop on Windows, not of this project. The same
applies to Docker Desktop on macOS (containers also run in a Linux VM).

### Options for Windows

| Option | Notes |
|--------|-------|
| **Native Windows eID middleware** (outside Docker) | The normal path on Windows. The official eid-mw has a Windows build that uses the Windows smart card service (WinSCard). This project, however, targets Linux/PKCS#11. |
| **`usbipd-win` (USB/IP) → WSL2 → container** | Possible but heavy and fragile: install `usbipd-win`, `bind`/`attach` the reader to WSL2, then pass the device into the container. Not configured here. |
| **Run on a Linux host/VM** | Simplest reliable option — run this stack on Linux (or a Linux VM) with the reader attached to it. |

## Troubleshooting

If you encounter issues with smart card access:

1. Make sure your smart card reader is properly connected to your host
2. This image runs its **own** `pcscd` inside the container, so the host's `pcscd` must **not** hold the reader. If a host `pcscd` is running, stop it so the container can open the reader: `sudo systemctl stop pcscd.service pcscd.socket`
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
   curl http://localhost:8099/
   ```

### Common Issues and Solutions

1. **"Could not find any reader with a card inserted"**
   - Verify your card reader is connected
   - Ensure the container has access to USB devices
   - Check if pcscd is running inside the container
   - Verify the PKCS11 library is correctly detected

2. **PCSCD cannot open the reader (`Open Port Failed` in logs)**
   - The host's `pcscd` is likely holding the reader — stop it: `sudo systemctl stop pcscd.service pcscd.socket`
   - Restart the container
   - Try running with `--privileged` flag for debugging

3. **PKCS11 library not found**
   - Check if eid-mw was installed correctly
   - Verify library path with: `docker exec beid-mw find / -name "libbeidpkcs11.so*"` 