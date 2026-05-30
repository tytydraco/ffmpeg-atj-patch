#!/bin/sh
# Fetch upstream x264 and apply atj-x264.patch. Usage:
#   build_x264 <prefix> <patch_file> [workdir]
build_x264() {
    prefix="$1"
    patch_file="$2"
    workdir="${3:-/tmp/x264-build}"

    x264_url="${X264_URL:-https://code.videolan.org/videolan/x264/-/archive/stable/x264-stable.tar.gz}"
    x264_dir="${X264_DIR:-x264-stable}"

    mkdir -p "$workdir"
    cd "$workdir" || true

    if [ ! -f x264-stable.tar.gz ]; then
        curl -fsSL "$x264_url" -o x264-stable.tar.gz
    fi

    rm -rf "$x264_dir"
    tar xf x264-stable.tar.gz
    cd "$x264_dir" || true

    if [ ! -f "$patch_file" ]; then
        echo "x264 patch not found: $patch_file" >&2
        return 1
    fi

    echo "Applying $(basename "$patch_file") to x264 ($x264_dir)..."
    patch -p1 < "$patch_file" || {
        echo "Failed to apply $patch_file — x264 upstream may have changed; update the patch or pin X264_URL." >&2
        return 1
    }

    ./configure \
        --prefix="$prefix" \
        --enable-static \
        --disable-cli \
        --disable-opencl
    make -j"${JOBS:-$(nproc)}"
    make install
}
