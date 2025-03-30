# Builder stage
FROM python:3.12-slim-bullseye AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    POETRY_VERSION=1.7.1 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="$POETRY_HOME/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy only requirements files
COPY pyproject.toml poetry.lock ./

# Install dependencies - fix lock file first, then install
RUN poetry lock --no-update
RUN poetry install --only main --no-root
RUN poetry add uvicorn

# Final stage
FROM python:3.12-slim-bullseye

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH" \
    PYKCS11LIB=/usr/lib/x86_64-linux-gnu/libbeidpkcs11.so.0

# Create non-root user
RUN useradd -m -u 1000 appuser

# Install system dependencies for pykcs11 and eID middleware
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libpcsclite-dev \
    pcscd \
    pcsc-tools \
    usbutils \
    wget \
    ca-certificates \
    gnupg \
    libc6 \
    libcap2-bin \
    opensc \
    && rm -rf /var/lib/apt/lists/*

# Copy the eID middleware package from docker directory
COPY docker/eid-archive_latest.deb /tmp/eid-archive_latest.deb

# Install the eID middleware package and its dependencies
RUN dpkg -i /tmp/eid-archive_latest.deb || true \
    && apt-get update \
    && apt-get install -f -y \
    && apt-get update \
    && apt-get install -y eid-mw \
    && rm -rf /var/lib/apt/lists/* \
    && rm /tmp/eid-archive_latest.deb

# Create pcscd directory with proper permissions
RUN mkdir -p /run/pcscd \
    && chmod 755 /run/pcscd \
    && chown appuser:appuser /run/pcscd

# Verify the library exists
RUN ls -la /usr/lib/libbeidpkcs11.so.0 || ls -la /usr/lib/x86_64-linux-gnu/libbeidpkcs11.so.0 || find / -name "libbeidpkcs11.so*" 2>/dev/null || echo "Library not found"

# Set working directory
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv ./.venv

# Copy application code
COPY ./beid_mw ./beid_mw

# Copy root package files
COPY pyproject.toml poetry.lock README.md ./

# Copy startup script
COPY docker/start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Install the package in development mode for proper module discovery
RUN pip install -e .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Allow binding to port 8080 - fix for symlink issue
RUN python_path=$(readlink -f /app/.venv/bin/python3) && \
    setcap 'cap_net_bind_service=+ep' $python_path

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Command to run the application
CMD ["/app/start.sh"] 