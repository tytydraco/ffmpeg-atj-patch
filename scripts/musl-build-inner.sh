#!/bin/sh
# Fully static musl ffmpeg build (run inside Alpine via build-static.sh).
set -eu

SRC="${SRC:-/src}"
PREFIX="${PREFIX:-/dist}"
JOBS="${JOBS:-$(nproc)}"
WORKDIR="/tmp/build"

export CFLAGS="-O2 -fPIC"
export CXXFLAGS="-O2 -fPIC"
export LDFLAGS="-static"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"

apk add --no-cache \
    build-base bash curl tar xz pkgconf diffutils \
    nasm yasm meson ninja \
    autoconf automake libtool perl \
    zlib-dev

mkdir -p "$PREFIX" "$WORKDIR"
cd "$WORKDIR"

fetch() {
    name="$1"
    url="$2"
    if [ ! -f "$name" ]; then
        curl -fsSL "$url" -o "$name"
    fi
}

fetch dav1d.tar.gz https://code.videolan.org/videolan/dav1d/-/archive/1.5.1/dav1d-1.5.1.tar.gz
rm -rf dav1d-1.5.1 && tar xf dav1d.tar.gz && cd dav1d-1.5.1
meson setup build --prefix="$PREFIX" --buildtype=release --default-library=static \
    -Denable_tools=false -Denable_examples=false
meson compile -C build -j"$JOBS" && meson install -C build
cd "$WORKDIR"

fetch libogg.tar.gz http://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.gz
rm -rf libogg-1.3.5 && tar xf libogg.tar.gz && cd libogg-1.3.5
./configure --prefix="$PREFIX" --disable-shared --enable-static
make -j"$JOBS" && make install
cd "$WORKDIR"

fetch libvorbis.tar.gz http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz
rm -rf libvorbis-1.3.7 && tar xf libvorbis.tar.gz && cd libvorbis-1.3.7
./configure --prefix="$PREFIX" --disable-shared --enable-static --with-ogg="$PREFIX"
make -j"$JOBS" && make install
cd "$WORKDIR"

fetch opus.tar.gz https://downloads.xiph.org/releases/opus/opus-1.5.2.tar.gz
rm -rf opus-1.5.2 && tar xf opus.tar.gz && cd opus-1.5.2
./configure --prefix="$PREFIX" --disable-shared --enable-static
make -j"$JOBS" && make install
cd "$WORKDIR"

fetch libvpx.tar.gz https://github.com/webmproject/libvpx/archive/refs/tags/v1.15.0.tar.gz
rm -rf libvpx-1.15.0 && tar xf libvpx.tar.gz && cd libvpx-1.15.0
./configure --prefix="$PREFIX" --disable-shared --enable-static \
    --disable-examples --disable-tools --disable-docs --disable-unit-tests \
    --enable-vp8 --enable-vp9 --size-limit=16384x16384
make -j"$JOBS" && make install
cd "$WORKDIR"

# shellcheck disable=SC1091
. "$SRC/scripts/build-x264.sh"
build_x264 "$PREFIX" "$SRC/yp3-x264.patch" "$WORKDIR/x264-build"

# shellcheck disable=SC1091
. "$SRC/scripts/fetch-ffmpeg.sh"
fetch_ffmpeg "$WORKDIR/ffmpeg"

cd "$WORKDIR/ffmpeg"
make distclean 2>/dev/null || true
./configure \
    --prefix="$PREFIX" \
    --enable-static \
    --disable-shared \
    --enable-gpl \
    --enable-libx264 \
    --enable-libdav1d \
    --enable-libopus \
    --enable-libvpx \
    --enable-libvorbis \
    --disable-network \
    --disable-debug \
    --pkg-config-flags="--static" \
    --extra-cflags="-static" \
    --extra-ldflags="-static"
make -j"$JOBS" && make install

echo "=== build complete ==="
file "$PREFIX/bin/ffmpeg"
ldd "$PREFIX/bin/ffmpeg" 2>&1 || true

if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
    chown -R "$HOST_UID:$HOST_GID" "$PREFIX" 2>/dev/null || true
fi
