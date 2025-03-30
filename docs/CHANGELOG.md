# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.7] - 2025-03-30

### Added
- Added development-focused Docker configuration
  - Created Dockerfile.dev for development workflow
  - Added development startup script (start-dev.sh)
  - Added source code mounting for live reload

### Changed
- Changed approach to use host's pcscd service instead of running in container
  - Removed container pcscd management
  - Added socket verification for host pcscd
  - Simplified Docker environment for development

### Fixed
- Fixed smart card reader access by using host's pcscd service
- Fixed application reload in development
- Simplified dependency installation in development container

## [0.1.6] - 2025-03-30

### Added
- Added OpenSC tools for better smart card debugging and testing
- Added device debugging and monitoring capabilities
- Added PC/SC system reset functionality in startup script

### Fixed
- Fixed CKR_DEVICE_ERROR (0x00000030) by improving PCSCD service handling
- Fixed device access by mounting full /dev directory
- Fixed environment variables for PC/SC system
- Improved pcscd service startup with better error handling
- Enhanced card reader detection with multiple strategies

## [0.1.5] - 2025-03-30

### Fixed
- Fixed Python module imports by installing the package in development mode
- Added proper PYTHONPATH environment variable for module discovery
- Improved package structure with proper __init__.py file
- Fixed module path resolution for test_pykcs11 script

## [0.1.4] - 2025-03-30

### Added
- Enhanced debugging capabilities
  - Added `/debug` API endpoint for system diagnostics
  - Added test_pykcs11.py script for library testing
  - Improved error handling with more detailed error messages
  - Added proper exception handling in API endpoints
  - Added logging with flexible directory fallback

### Changed
- Improved PyKCS11 library integration
  - Better error handling for PyKCS11 integration
  - Improved diagnostics for smart card access

### Fixed
- Fixed Internal Server Error responses
- Fixed permissions for accessing smart card devices
- Fixed logger to handle permission issues gracefully

## [0.1.3] - 2025-03-30

### Added

- Added docker-compose.yml for simplified deployment
- Added network host mode for better connectivity with the host
- Added proper capabilities for network binding

### Fixed

- Fixed network binding issues preventing access to the server
- Added explicit worker configuration to uvicorn
- Improved server startup logging
- Fixed missing libcap2-bin package needed for setcap command
- Fixed setcap command to handle Python symlinks correctly

## [0.1.2] - 2025-03-30

### Added

- Enhanced logging and debugging capabilities:
  - Added application logger module (beid_mw/logger.py)
  - Added debug.sh script for comprehensive diagnostics
  - Added pcsc-tools and usbutils to Docker image
  - Added verbose logging in container startup script
  - Extended debugging documentation

### Fixed

- Fixed pcscd service permission issue by creating /run/pcscd with proper ownership
- Corrected PYKCS11LIB environment variable to point to actual library location
- Fixed startup script syntax errors by moving it to an external file
- Resolved shell script indentation issues causing server startup failures

## [0.1.1] - 2025-03-30

### Added

- Docker configuration for lightweight deployment
  - Multi-stage Dockerfile with Python 3.12 slim-bullseye base image
  - .dockerignore file for optimized build context
  - Non-root user for security
  - Poetry-based dependency management
  - Proper system dependencies for pykcs11
- Added Belgian eID middleware installation to Docker image
  - Included required system dependencies (pcscd, etc.)
  - Configured proper eID library access
- Added explicit PYKCS11LIB environment variable in Docker
- Added integrated startup script to run pcscd within the container
- Created Docker documentation with usage instructions (docker/README.md)

### Changed

- Project structure updated to include docker configuration files
- Improved Docker portability by self-containing all required services

### Fixed

- Added explicit uvicorn dependency in Dockerfile and pyproject.toml
- Fixed Docker image build to include all required dependencies
- Fixed casing in Dockerfile for consistency (FROM ... AS)
- Fixed poetry dependency installation by syncing lock file with pyproject.toml
- Updated deprecated `--no-dev` flag to `--only main` in poetry command
- Fixed eID middleware package name from 'beid' to 'eid-mw'
- Fixed eID middleware installation by adding second apt-get update after repository configuration

## [0.1.0] - Initial Release

### Added

- Initial FastAPI server setup
- Basic project structure with Poetry
- PYKCS11 integration
