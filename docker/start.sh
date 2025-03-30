#!/bin/bash
# Enable verbose logging
set -x

# Kill any existing pcscd
pkill pcscd || true
sleep 1

# Start pcscd service in dedicated foreground mode
pcscd -f --debug &
PCSCD_PID=$!

# Wait for pcscd to start
sleep 3

# Verify pcscd is running
if ! ps -p $PCSCD_PID > /dev/null; then
    echo "Error: pcscd failed to start"
    # Try alternative approach
    pcscd --foreground --debug &
    PCSCD_PID=$!
    sleep 2
fi

# Monitor USB devices - try to reset the reader
echo "Resetting PC/SC system..."
echo "Before reset:"
pcsc_scan -n

# Try resetting PC/SC system
systemctl reset-failed pcscd.service || true
systemctl restart pcscd.service || true

# Monitor devices after reset
echo "After reset:"
pcsc_scan -n || echo "pcsc_scan failed"

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

# List all connected devices
echo "Connected USB devices:"
lsusb || echo "lsusb not available"

# Check if OpenSC can detect the card
echo "Checking OpenSC card detection:"
opensc-tool -l || echo "opensc-tool failed"

# Test PKCS11 with OpenSC tools
echo "Testing PKCS11 with OpenSC:"
pkcs11-tool --module $PYKCS11LIB -L || echo "pkcs11-tool failed"

# Print environment
echo "Environment variables:"
env | grep -E 'PYKCS11|PC|SC'

# Start the application with debug logging
echo "Starting FastAPI application on 0.0.0.0:8080..."
exec uvicorn beid_mw.main:app --host 0.0.0.0 --port 8080 --log-level debug --workers 1 