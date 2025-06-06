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

> **Note:**  
> If you are using Docker, you do **not** need to install the Belgian eID middleware or other system dependencies on your host. The Docker container includes everything required.

### Python Dependencies

This project uses [Poetry](https://python-poetry.org/) for dependency management.

Install Poetry (if not already installed):

```sh
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"
```

Install Python dependencies:

```sh
poetry install
```

## Running the Application

Start the FastAPI server (from the project root):

```sh
poetry run uvicorn beid_mw.main:app --host 0.0.0.0 --port 8080 --log-level debug
```

The API will be available at [http://localhost:8080](http://localhost:8080).

## Docker

You can run the application in Docker for easier setup and deployment.

### Development (with live reload)

```sh
cd docker
docker-compose up --build
```

### Production

```sh
docker build -t beid-mw:latest -f docker/Dockerfile .
docker run -d --name beid-mw -p 8080:8080 --privileged \
    -v /dev/bus/usb:/dev/bus/usb \
    -v /run/pcscd:/run/pcscd \
    beid-mw:latest
```

See [docker/README.md](docker/README.md) for more details and troubleshooting.

## Testing PKCS#11 Integration

You can run the standalone test script to diagnose PyKCS11 and eID middleware issues:

```sh
poetry run python beid_mw/test_pykcs11.py
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