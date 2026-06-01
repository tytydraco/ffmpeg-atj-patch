#!/usr/bin/env bash
# Dev build (glibc): produces local/bin/ffmpeg using system codec libraries.
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
PREFIX="$SCRIPT_DIR/local"
BUILD="$SCRIPT_DIR/.build"
JOBS="$(nproc)"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/scripts/build-x264.sh"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/scripts/fetch-ffmpeg.sh"

build_x264 "$PREFIX" "$SCRIPT_DIR/yp3-x264.patch" "$BUILD/x264"
fetch_ffmpeg "$BUILD/ffmpeg"

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

cd "$BUILD/ffmpeg"
make distclean 2>/dev/null || true
./configure \
    --prefix="$PREFIX" \
    --enable-gpl \
    --enable-libx264 \
    --enable-libdav1d \
    --enable-libopus \
    --enable-libvpx \
    --enable-libvorbis \
    --enable-libmp3lame \
    --disable-doc \
    --extra-cflags="-I$PREFIX/include" \
    --extra-ldflags="-L$PREFIX/lib"
make -j"$JOBS"
make install

echo "Installed: $PREFIX/bin/ffmpeg"