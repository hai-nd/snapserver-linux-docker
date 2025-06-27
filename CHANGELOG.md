# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-06-27
### Added
- Initial public release of `snapserver-linux-docker`
- Snapserver v0.31.0 built from source
- Included:
  - `librespot-java` + `librespot-api-1.6.3.jar`
  - `shairport-sync` (AirPlay 2, ALAC, metadata enabled)
  - Metadata control scripts for `mopidy`, `mpd`, `librespot-java`
- s6-overlay based multi-service orchestration
- Snapweb frontend included for switching source
- Centralized `/config` folder for editable settings
- Docker image designed to run on Linux hosts (not Docker Desktop)
