#!/bin/sh
# Fetch upstream ffmpeg sources. Usage:
#   fetch_ffmpeg <dest_dir>
fetch_ffmpeg() {
    dest="$1"

    version="ffmpeg-8.1.tar.xz"

    url="${FFMPEG_URL:-"https://ffmpeg.org/releases/$version"}"
    tarball="${FFMPEG_TARBALL:-"$version"}"
    srcdir="${FFMPEG_SRCDIR:-"${version%.tar.xz}"}"

    mkdir -p "$(dirname "$dest")"
    work="$(dirname "$dest")"

    if [ -d "$dest/.ffmpeg-fetched" ]; then
        return 0
    fi

    cd "$work" || true
    if [ ! -f "$tarball" ]; then
        echo "Downloading $url ..."
        curl -fsSL "$url" -o "$tarball"
    fi

    rm -rf "$srcdir"
    tar xf "$tarball"
    rm -rf "$dest"
    mv "$srcdir" "$dest"
    touch "$dest/.ffmpeg-fetched"
    echo "ffmpeg sources ready at $dest"
}
