# snapserver-linux-docker

A custom Alpine-based Docker image for running Snapserver with metadata and streaming plugins on Linux systems.

## ✨ Features

- **Snapserver v0.29.0** with [Snapweb UI](https://github.com/badaix/snapweb)
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
