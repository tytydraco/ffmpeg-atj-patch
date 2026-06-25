#!/usr/bin/env bash
# Portable fully-static musl ffmpeg (requires Docker). Output: .dist/musl-x86_64/bin/
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
DIST64="$SCRIPT_DIR/.dist/musl-arm64"
STATIC64="$SCRIPT_DIR/static-arm64"
IMAGE="${ALPINE_IMAGE:-alpine:3.21}"

command -v docker >/dev/null || { echo "docker required"; exit 1; }

mkdir -p "$DIST64"
chmod +x "$SCRIPT_DIR/scripts/musl-build-inner.sh"

docker buildx create --use
docker run --privileged --rm tonistiigi/binfmt --install all

echo "Building static musl ffmpeg in $IMAGE → $DIST64 & $DIST32"
docker run --rm \
    --platform linux/arm64 \
    -v "$SCRIPT_DIR:/src:ro" \
    -v "$DIST64:/dist" \
    -e SRC=/src \
    -e PREFIX=/dist \
    -e JOBS="$(nproc)" \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    "$IMAGE" \
    /src/scripts/musl-build-inner.sh

chown -R "$(id -u):$(id -g)" "$DIST64" 2>/dev/null || \
    echo "Note: run sudo chown -R $(id -u):$(id -g) $DIST64"

echo
ls -lh "$DIST64/bin/ffmpeg" "$DIST64/bin/ffprobe"
file "$DIST64/bin/ffmpeg"
ldd "$DIST64/bin/ffmpeg" 2>&1 || true

cp "$DIST64/bin/ffmpeg" "$STATIC64"
cp "$DIST64/bin/ffprobe" "$STATIC64"
