# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Belgian eID Middleware REST API — a FastAPI microservice that reads Belgian electronic identity cards via PKCS#11/PyKCS11 and exposes card data through HTTP endpoints.

## Commands

```bash
# Install dependencies
uv sync

# Run the server (requires eID middleware + card reader)
export PYKCS11LIB=/usr/lib/x86_64-linux-gnu/libbeidpkcs11.so.0
uv run uvicorn beid_mw.main:app --host 0.0.0.0 --port 8080 --log-level debug

# Test PKCS#11 connectivity (diagnostic script)
uv run python beid_mw/test_pykcs11.py

# Docker development (uses host pcscd service)
cd docker && docker-compose up --build

# API endpoints
curl http://localhost:8080/          # version info
curl http://localhost:8080/beid      # read eID card (add ?certs=true for certificates)
curl http://localhost:8080/debug     # system diagnostics
```

## Architecture

- **`beid_mw/main.py`** — FastAPI app with three endpoints (`/`, `/beid`, `/debug`). Core logic is in `eid2dict()` which opens PKCS#11 sessions, reads card attributes, and decodes them by type (UTF-8, ASCII, binary, base64 blobs).
- **`beid_mw/logger.py`** — Dual console+file logging with directory fallback (`/app` → `/tmp` → home → cwd).
- **`beid_mw/test_pykcs11.py`** — Standalone diagnostic script for verifying PyKCS11 library loading and smart card reader detection.
- **`docker/`** — Production (`Dockerfile`) and dev (`Dockerfile.dev`) images. Production uses multi-stage build with Belgian eID .deb package. Dev mounts host pcscd socket. Docker Compose runs in host network mode with privileged access for USB device communication.

## Key Environment Variables

- `PYKCS11LIB` — Path to the PKCS#11 shared library (platform-specific, required)
- `USE_HOST_PCSCD` — Set to use host's pcscd service instead of container's (dev Docker)

## Hardware Dependency

This project interfaces with physical smart card readers. Most functionality cannot be tested without a Belgian eID card inserted in a connected reader. The `/debug` endpoint and `test_pykcs11.py` script help diagnose connectivity issues without a card present.
