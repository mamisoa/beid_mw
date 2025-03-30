#!/bin/bash
# Enable verbose logging
set -x

echo "=== Development Mode ==="
echo "Using host's pcscd service"

# Make sure we can connect to the host's pcscd
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
elif [ -e "/var/run/pcscd/pcscd.comm" ]; then
  echo "Found pcscd socket at /var/run/pcscd/pcscd.comm"
else
  echo "Warning: pcscd socket not found. Make sure pcscd is running on the host"
  echo "Try: sudo systemctl start pcscd.service"
fi

# Check if host pcscd service is accessible
echo "Testing connection to host pcscd service:"
pcsc_scan -n || echo "pcsc_scan failed"

# List all connected devices
echo "Connected USB devices:"
lsusb || echo "lsusb not available"

# Check if OpenSC can detect the card
echo "Checking OpenSC card detection:"
opensc-tool -l || echo "opensc-tool failed"

# Test PKCS11 with OpenSC tools
echo "Testing PKCS11 with OpenSC:"
pkcs11-tool --module $PYKCS11LIB -L || echo "pkcs11-tool failed"

# Install dependencies with poetry if we're in development mode
if [ -f "pyproject.toml" ]; then
  echo "Installing dependencies with Poetry..."
  poetry install
  
  # Start the application with debug logging
  echo "Starting FastAPI application on 0.0.0.0:8080..."
  exec poetry run uvicorn beid_mw.main:app --host 0.0.0.0 --port 8080 --log-level debug --reload
else
  echo "Starting FastAPI application on 0.0.0.0:8080..."
  exec uvicorn beid_mw.main:app --host 0.0.0.0 --port 8080 --log-level debug --reload
fi 