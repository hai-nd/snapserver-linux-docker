<p align="center">
  <img src="https://github.com/hai-nd/snapserver-linux-docker/raw/main/snapserver.png" alt="snapserver-linux-docker banner" />
</p>

# snapserver-linux-docker

A custom Alpine-based Docker image for running Snapserver with metadata and streaming plugins on Linux systems.

## ✨ Features

- **Snapserver v0.31.0** with [Snapweb UI](https://github.com/badaix/snapweb)
- **librespot-java** for Spotify playback with metadata support
- **Shairport-sync** for AirPlay streaming (with pipe output)
- Metadata plugin support for Mopidy, MPD, Librespot
- Pre-configured `s6-overlay` for process supervision
- Suitable for headless Linux streamboxes

## 📁 Directory Structure

```
.
├── Alpine-dockerfile
├── config/
│   ├── meta_mopidy.py
│   ├── meta_mpd.py
│   ├── meta_librespot-java.py
│   ├── config.toml
│   ├── snapserver.conf
│   ├── shairport-sync.conf
│   ├── credentials.json
│   └── librespot-api-1.6.3.jar
├── s6-overlay/
│   └── s6-rc.d/
│       ├── 01-startup/
│       ├── 02-dbus/
│       ├── 03-avahi/
│       ├── 04-nqptp/
│       ├── 05-snapserver/
│       └── 06-librespot/
└── README.md
```
## 🐳 Docker Setup

### Option 1: Run with `docker run`

```bash
docker run -d \
  --name snapserver \
  --network host \
  --restart unless-stopped \
  -v /etc/snapserver/config:/config \
  haingo65/snapserver-linux-docker:latest
```
### Option 2: Use `docker-compose.yml`

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  snapserver:
    image: haingo65/snapserver-linux-docker:latest
    container_name: snapserver
    network_mode: host
    restart: unless-stopped
    volumes:
      - /etc/snapserver/config:/config
```
- Then run:
```bash
docker compose up -d
```

## 🚀 Build Instructions

```bash
git clone https://github.com/YOUR_USERNAME/snapserver-linux-docker.git
cd snapserver-linux-docker
docker build -f Alpine-dockerfile -t snapserver-linux .
```

## 🧠 Notes

- This image is built for **Linux only**. On Windows/macOS, mDNS and metadata streaming may not work correctly.
- For best results, run with `--net=host` on Linux.

## 🙏 Credits

Maintained by [Hai Ngo](https://github.com/hai-nd), based on the work of Mike Brady, badaix, and the Snapcast community.
