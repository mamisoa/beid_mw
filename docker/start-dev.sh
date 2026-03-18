#!/bin/bash
set -x

echo "=== Development Mode ==="
echo "Using host pcscd service via mounted socket and libpcsclite"

# Check PKCS11 library
echo "PYKCS11LIB is set to: $PYKCS11LIB"
if [ -f "$PYKCS11LIB" ]; then
  echo "PKCS11 library exists at $PYKCS11LIB"
else
  echo "Looking for PKCS11 library..."
  LIB_PATH=$(find / -name "libbeidpkcs11.so*" 2>/dev/null | head -1)
  if [ -n "$LIB_PATH" ]; then
    echo "PKCS11 library found at $LIB_PATH, updating environment variable"
    export PYKCS11LIB=$LIB_PATH
  else
    echo "Warning: PKCS11 library not found"
  fi
fi

# Verify pcscd socket exists
if [ -e "/run/pcscd/pcscd.comm" ]; then
  echo "Found pcscd socket at /run/pcscd/pcscd.comm"
else
  echo "ERROR: pcscd socket not found at /run/pcscd/pcscd.comm"
  echo "Make sure pcscd is running on the host: sudo systemctl start pcscd"
fi

# List connected USB devices
echo "Connected USB devices:"
lsusb || echo "lsusb not available"

# Install dependencies with uv if we're in development mode
if [ -f "pyproject.toml" ]; then
  echo "Installing dependencies with uv..."
  uv sync

  # Start the application with debug logging
  echo "Starting FastAPI application on 0.0.0.0:8080..."
  exec uv run uvicorn beid_mw.main:app --host 0.0.0.0 --port 8080 --log-level debug --reload
else
  echo "Starting FastAPI application on 0.0.0.0:8080..."
  exec uvicorn beid_mw.main:app --host 0.0.0.0 --port 8080 --log-level debug --reload
fi
