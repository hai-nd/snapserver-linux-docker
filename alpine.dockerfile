# The alpine dockerfile for librespot-java, shairport-sync, snapserver with snapweb
# maintained by Hai Ngo, inspired by several source on the internet
# ARG alpine_version=3.20
ARG S6_OVERLAY_VERSION=3.2.0.0

FROM docker.io/alpine:latest AS builder
RUN apk add --no-cache \
    # LIBRESPOT
    #cargo \
    #clang18-dev \
    #git \
    #musl-dev \
    #pkgconfig \
    # SNAPCAST
    cmake \
    alsa-lib-dev \
    avahi-dev \
    bash \
    boost-dev \
    expat-dev \
    flac-dev \
    git \
    libvorbis-dev \
    npm \
    soxr-dev \
    opus-dev \
    # SHAIRPORT
    alpine-sdk \
    alsa-lib-dev \
    autoconf \
    automake \
    avahi-dev \
    dbus \
    ffmpeg-dev \
    git \
    libtool \
    libdaemon-dev \
    libplist-dev \
    libsodium-dev \
    libgcrypt-dev \
    libconfig-dev \
    openssl-dev \
    popt-dev \
    soxr-dev \
    xmltoman \
    xxd

###### SNAPCAST BUNDLE START ###### 
FROM builder AS snapcast

### SNAPSERVER ### git checkout 
RUN git clone https://github.com/badaix/snapcast.git /snapcast \
    && cd snapcast \
    && git checkout tags/v0.31.0
WORKDIR /snapcast
RUN cmake -S . -B build -DBUILD_CLIENT=OFF \
    && cmake --build build -j $(( $(nproc) -1 )) --verbose \
    && strip -s ./bin/snapserver
WORKDIR /

# Gather all shared libaries necessary to run the executable
RUN mkdir /snapserver-libs \
    && ldd /snapcast/bin/snapserver | cut -d" " -f3 | xargs cp --dereference --target-directory=/snapserver-libs/
### SNAPSERVER END ###

### SNAPWEB ### git checkout 66a15126578548ed544ab5b59acdece3825c2699
RUN git clone https://github.com/badaix/snapweb.git
WORKDIR /snapweb
RUN git checkout tags/v0.8.0
ENV GENERATE_SOURCEMAP="false"
RUN npm install -g npm@latest \
    && npm ci \
    && npm run build
WORKDIR /
### SNAPWEB END ###
###### SNAPCAST BUNDLE END ######

###### SHAIRPORT BUNDLE START ######
FROM builder AS shairport

### NQPTP ###  checkout ee6663c99d95f9d25fbe07b0982a3c3b622ba0f5 checkout tags/v1.2.4
RUN git clone https://github.com/mikebrady/nqptp.git /nqptp
WORKDIR /nqptp
RUN git checkout ee6663c99d95f9d25fbe07b0982a3c3b622ba0f5 
RUN autoreconf -i \
    && ./configure \
    && make -j $(( $(nproc) -1 ))
WORKDIR /
### NQPTP END ###

### ALAC ###
RUN git clone https://github.com/mikebrady/alac
WORKDIR /alac
RUN git checkout 34b327964c2287a49eb79b88b0ace278835ae95f \
    && autoreconf -i \
    && ./configure \
    && make -j $(( $(nproc) -1 )) \
    && make install
WORKDIR /
### ALAC END ###

### SPS ### git checkout 654f59693240420ea96dba1354a06ce44d1293d7
RUN git clone https://github.com/mikebrady/shairport-sync.git /shairport\
    && cd /shairport \
    && git checkout 654f59693240420ea96dba1354a06ce44d1293d7
WORKDIR /shairport/build
RUN autoreconf -i ../ \
    && ../configure --sysconfdir=/etc \
                    --with-soxr \
                    --with-avahi \
                    --with-pipe \
                    --with-ssl=openssl \
                    --with-airplay-2 \
                    --with-stdout \
                    --with-metadata \
                    --with-apple-alac \
    && DESTDIR=install make -j $(( $(nproc) -1 )) install

WORKDIR /

# Gather all shared libaries necessary to run the executable
RUN mkdir /shairport-libs \
    && ldd /shairport/build/shairport-sync | cut -d" " -f3 | xargs cp --dereference --target-directory=/shairport-libs/
### SPS END ###
###### SHAIRPORT BUNDLE END ######

###### BASE START ######
FROM docker.io/alpine:latest AS base
ARG S6_OVERLAY_VERSION
RUN apk add --no-cache \
    avahi \
    dbus \
    fdupes
# Copy all necessary libaries into one directory to avoid carring over duplicates
# Removes all libaries that will be installed in the final image
##### COPY --from=librespot /librespot-libs/ /tmp-libs/
COPY --from=snapcast /snapserver-libs/ /tmp-libs/
COPY --from=shairport /shairport-libs/ /tmp-libs/
RUN fdupes -d -N /tmp-libs/ /usr/lib/

# Install s6
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
    https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
    && rm -rf /tmp/*

###### BASE END ######

###### MAIN START ######
FROM docker.io/alpine:latest

ENV S6_CMD_WAIT_FOR_SERVICES=1
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

RUN apk add --no-cache \
            bash \
            avahi \
            dbus \
            nano \
            procps \
            python3 \
            py3-pip \
            py3-gobject3 \
            py3-requests \
            py3-websocket-client \
            py3-musicbrainzngs \
            dumb-init \
            openjdk17-jre \
            alsa-utils \
            nodejs \
            jq \
            npm \
            curl \
    && npm install -g wscat \
    && rm -rf /lib/apk/db/*

# Copy extracted s6-overlay and libs from base
COPY --from=base /command /command/
COPY --from=base /package/ /package/
COPY --from=base /etc/s6-overlay/ /etc/s6-overlay/
COPY --from=base init /init
COPY --from=base /tmp-libs/ /usr/lib/

# Copy all necessary files from the builders
### COPY --from=librespot /librespot/target/release/librespot /usr/local/bin/
COPY --from=snapcast /snapcast/bin/snapserver /usr/local/bin/
COPY --from=snapcast /snapweb/dist /usr/share/snapserver/snapweb
COPY --from=shairport /shairport/build/shairport-sync /usr/local/bin/
COPY --from=shairport /nqptp/nqptp /usr/local/bin/

# Copy plugin jar + toml
COPY ./config/librespot-api-1.6.3.jar /usr/local/bin/
COPY ./config/config.toml /usr/local/bin/
RUN chmod 644 /usr/local/bin/config.toml

# Copy local files
COPY ./s6-overlay/s6-rc.d /etc/s6-overlay/s6-rc.d
RUN chmod +x /etc/s6-overlay/s6-rc.d/01-startup/script.sh
RUN chmod +x /etc/s6-overlay/s6-rc.d/02-dbus/data/check
RUN chmod -R 777 /etc/s6-overlay
RUN mkdir -p /var/run/dbus/

# Make /config and copy all the files
RUN mkdir -p /config
COPY ./config/* /config/
RUN chmod 644 /config/*.py /config/*.conf /config/*.json

# Symbolic link for the plugins folder to /config to avoid overwriting /etc
RUN ln -s /config /etc/plug-ins

# Set the PATH environment variable
ENV PATH="/command:$PATH"

ENTRYPOINT ["/init"]
###### MAIN END ######