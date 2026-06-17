#!/bin/bash
# Enable verbose logging
set -x

# Kill any existing pcscd
pkill pcscd || true
sleep 1

# Start pcscd in the background (foreground mode keeps it in our process tree).
# --debug is intentionally omitted: it floods the logs and slows card access.
pcscd -f &
PCSCD_PID=$!

# Give pcscd a moment to enumerate readers
sleep 3

# Verify pcscd is actually running (kill -0 works without procps installed)
if ! kill -0 "$PCSCD_PID" 2>/dev/null; then
  echo "Warning: pcscd did not stay up, retrying..."
  pcscd -f &
  PCSCD_PID=$!
  sleep 2
fi

# Resolve the PKCS#11 library
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

# Non-blocking reader diagnostic. pcsc_scan loops forever when a reader is
# present, so cap it with `timeout` and never let it block startup.
echo "Reader scan (best effort, 5s):"
timeout 5 pcsc_scan -n 2>/dev/null || echo "pcsc_scan skipped/timed out (not fatal)"

# Start the application with debug logging
echo "Starting FastAPI application on 0.0.0.0:8099..."
exec uvicorn beid_mw.main:app --host 0.0.0.0 --port 8099 --log-level debug --workers 1
