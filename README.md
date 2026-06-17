# Belgian eID Middleware FastAPI

This project provides a FastAPI-based API for accessing Belgian eID card data using the official eID middleware and PKCS#11.

## Features

- REST API to access eID card data and certificates
- Diagnostics and debug endpoints
- Docker support for both production and development
- Standalone test script for PyKCS11 troubleshooting

## Prerequisites

### System Dependencies

If you are running the application **without Docker** (natively on your system), you need the following system packages to build and use the PyKCS11 library and the Belgian eID middleware:

```sh
sudo apt update
sudo apt install python3.12-dev build-essential swig libssl-dev \
    libpcsclite-dev pcscd pcsc-tools usbutils opensc curl wget ca-certificates gnupg
```

You also need the Belgian eID middleware installed **on your host** if running natively. On Debian/Ubuntu:

```sh
wget https://eid.belgium.be/sites/default/files/software/eid-archive_latest.deb
sudo dpkg -i eid-archive_latest.deb || true
sudo apt-get update
sudo apt-get install -f -y
sudo apt-get install eid-mw
```

Set the `PYKCS11LIB` environment variable for Ubuntu (add this to your shell profile):

```sh
echo 'export PYKCS11LIB=/usr/lib/x86_64-linux-gnu/libbeidpkcs11.so.0' >> ~/.bashrc
```

> **Note:**
> If you are using Docker, you still need `pcscd` and `libpcsclite1` installed on the host (see Docker section below).

### Additional requirement for Ubuntu 24.04: Service Policy (Polkit) for pcscd

On Ubuntu 24.04, it is recommended to set up a specific Polkit rule to allow access to **pcscd** only for the user or group of your choice.

#### Create a specific Polkit rule to allow **pcscd**

*(clean method: only grant access to the user or group you choose)*

##### 1. Choose the target

- **By user**: allow only your account `mamisoa`.
- **By group**: create a group (e.g. `scard`) and add all users/services that need access to the reader.

---

##### 2. (Optional) create the `scard` group

```bash
sudo groupadd scard             # ignore if the group already exists
sudo usermod -aG scard mamisoa  # add yourself to the group
# log out / log back in to apply the new group
```

---

##### 3. Write the Polkit rule

```bash
sudo nano /etc/polkit-1/rules.d/49-pcsc-beid.rules
```

**Content if you choose the user:**

```javascript
// Allow user mamisoa to access pcscd
polkit.addRule(function(action, subject) {
  var pcsc = action.id == "org.debian.pcsc-lite.access_pcsc" ||
             action.id == "org.debian.pcsc-lite.access_card";
  if (pcsc && subject.user == "mamisoa") {
    return polkit.Result.YES;
  }
});
```

**Content if you prefer the group:**

```javascript
// Allow all members of the scard group to access pcscd
polkit.addRule(function(action, subject) {
  var pcsc = action.id == "org.debian.pcsc-lite.access_pcsc" ||
             action.id == "org.debian.pcsc-lite.access_card";
  if (pcsc && subject.isInGroup("scard")) {
    return polkit.Result.YES;
  }
});
```

> The file must end with the **`.rules`** extension and contain ES5 JavaScript.
> The `49-` prefix ensures the rule is read after the package defaults.

---

##### 4. Reload Polkit and pcscd

```bash
sudo systemctl restart polkit.service
sudo systemctl restart pcscd.service
```

---

##### 5. Restart your API service

```bash
# system service
sudo systemctl restart beid_mw.service

# or user service if you moved it
systemctl --user restart beid_mw.service
```

---

##### 6. Quick check

```bash
pcsc_scan          # should list your reader without authorization error
curl http://localhost:8099/beid?certs=false   # 200 OK response from your API
```

If both commands succeed, the Polkit rule is working: your service can access the reader/card without getting `CKR_DEVICE_ERROR`.

### Python Dependencies

This project uses [uv](https://docs.astral.sh/uv/) for dependency management.

Install uv (if not already installed):

```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Install Python dependencies:

```sh
uv sync
```

## Running the Application

Start the FastAPI server (from the project root):

```sh
uv run uvicorn beid_mw.main:app --host 0.0.0.0 --port 8099 --log-level debug
```

The API will be available at [http://localhost:8099](http://localhost:8099).

## Docker

You can run the application in Docker for easier setup and deployment.

### Host prerequisites

There are two deployment modes with different host requirements:

- **Development image** (`Dockerfile.dev`, used by `docker compose`): relies on the host's `pcscd` service and `libpcsclite` libraries (mounted into the container to avoid a protocol version mismatch). Install and start them on the host:

  ```sh
  sudo apt install pcscd libpcsclite1 libpcsclite-dev
  sudo systemctl start pcscd
  ```

- **Production image** (`Dockerfile`): fully self-contained. It bundles the eID middleware and runs its **own** `pcscd` inside the container, so the host needs neither `pcscd` nor the eID middleware installed — only the card reader connected and **free** (the host's `pcscd` must not hold it; stop it with `sudo systemctl stop pcscd.service pcscd.socket`, or simply don't run it on a dedicated host).

The eID middleware only needs to be installed on the host if you run the application **natively** (see [System Dependencies](#system-dependencies) above).

### Development (with live reload)

```sh
cd docker
docker compose up --build
```

The container:
- Mounts the project directory for live reload
- Mounts the host's `libpcsclite.so.1` and `libpcsclite_real.so.1` to match the host's pcscd protocol version
- Mounts the host's pcscd socket (`/run/pcscd`)
- Runs in privileged mode with host network for USB device access

### Production

The production image is self-contained (its own `pcscd`, eID middleware baked in). It only needs the USB reader passed through — no host `pcscd` socket or `libpcsclite` mounts:

```sh
docker build -t beid-mw:latest -f docker/Dockerfile .
docker run -d --name beid-mw -p 8099:8099 --privileged \
    -v /dev/bus/usb:/dev/bus/usb \
    --device-cgroup-rule='c 189:* rmw' \
    beid-mw:latest
```

Make sure the host's `pcscd` is not holding the reader (see Host prerequisites above); otherwise the container's `pcscd` cannot open it.

This image is portable: build it once and ship it to another Linux host with `docker save | docker load` (or a registry) — the target only needs Docker and the card reader.

### Known limitations / TODO

- **x86_64 only**: library paths are hardcoded to `/usr/lib/x86_64-linux-gnu/`. ARM64 would require different paths.
- **Host pcscd dependency (development image only)**: the `Dockerfile.dev` image relies on the host's `pcscd` service and mounts its `libpcsclite` to avoid a protocol version mismatch. The **production** image (`Dockerfile`) runs its own `pcscd` and has no such dependency — it only needs exclusive access to the USB reader.
- **Ubuntu 25.10 specific**: tested on Ubuntu 25.10 (questing) with pcsc-lite 2.3.3. Other distributions or versions with different pcsc-lite versions may require adjustments to the mounted libraries.

See [docker/README.md](docker/README.md) for more details and troubleshooting.

## Testing PKCS#11 Integration

You can run the standalone test script to diagnose PyKCS11 and eID middleware issues:

```sh
uv run python beid_mw/test_pykcs11.py
```

This will check:

- PyKCS11 import
- PKCS#11 library loading
- Card reader slot detection

## Troubleshooting

- Make sure your smart card reader is connected and a card is inserted.
- Ensure `pcscd` is running:  
  `sudo systemctl start pcscd`
- Check the `PYKCS11LIB` environment variable points to the correct library (e.g., `/usr/lib/x86_64-linux-gnu/libbeidpkcs11.so.0`).
- Use the `/debug` API endpoint for diagnostics.

## License

MIT License

---

For more details, see the [CHANGELOG](docs/CHANGELOG.md).
