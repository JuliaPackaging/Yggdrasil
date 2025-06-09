# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland_protocols"
version = v"1.44"

# Collection of sources required to build Wayland-protocols
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/$(version.major).$(version.minor)/downloads/wayland-protocols-$(version.major).$(version.minor).tar.xz",
                  "3df1107ecf8bfd6ee878aeca5d3b7afd81248a48031e14caf6ae01f14eebb50e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-protocols*/
mkdir build && cd build

# Find and use the actual wayland-scanner binary
WAYLAND_SCANNER=$(find $prefix -name "wayland-scanner" -type f 2>/dev/null | head -1)
if [ -z "$WAYLAND_SCANNER" ]; then
    # If not found in prefix, try the host system
    WAYLAND_SCANNER=$(which wayland-scanner 2>/dev/null)
fi

if [ -n "$WAYLAND_SCANNER" ]; then
    echo "Found wayland-scanner at: $WAYLAND_SCANNER"
    
    # Create a custom pkg-config wrapper that returns the correct path
    mkdir -p custom-pkgconfig
    cat > custom-pkgconfig/pkg-config <<'EOF'
#!/bin/bash
if [[ "$*" == *"wayland-scanner"* && "$*" == *"--variable=wayland_scanner"* ]]; then
    echo "$WAYLAND_SCANNER"
else
    exec /usr/bin/pkg-config "$@"
fi
EOF
    chmod +x custom-pkgconfig/pkg-config
    
    # Put our custom pkg-config first in PATH
    export PATH="$(pwd)/custom-pkgconfig:$PATH"
    
    # Also create native file as backup
    cat > native.ini <<EOF
[binaries]
wayland-scanner = '$WAYLAND_SCANNER'
EOF
    
    meson setup .. -Dtests=false --cross-file="${MESON_TARGET_TOOLCHAIN}" --native-file=native.ini
else
    echo "wayland-scanner not found, trying default setup..."
    export PATH="$prefix/bin:$PATH"
    meson setup .. -Dtests=false --cross-file="${MESON_TARGET_TOOLCHAIN}"
fi

ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Wayland_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
