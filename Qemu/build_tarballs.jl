using BinaryBuilder

name = "Qemu"
version = v"2.12.50"

# Collection of sources required to build libffi
sources = [
    "https://github.com/Keno/qemu.git" =>
    "2ed3b3c2f2c79208b689673a257ab04a6aa984a3",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qemu
./configure --target-list=x86_64-softmmu --disable-cocoa --prefix=$prefix
echo '#!/bin/true ' > /usr/bin/SetFile
echo '#!/bin/true ' > /usr/bin/Rez
chmod +x /usr/bin/Rez
chmod +x /usr/bin/SetFile
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # For now, only build for MacOS
    BinaryProvider.MacOS(),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "x86_64-softmmu/qemu-system-x86_64", :qemu_x86_64)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need Pixman
    "https://github.com/staticfloat/PixmanBuilder/releases/download/v0.34.0-0/build.jl",
    # We need Glib
    "https://github.com/staticfloat/GlibBuilder/releases/download/v2.54.2-2/build.jl",
    # We need Pcre
    "https://github.com/staticfloat/PcreBuilder/releases/download/v8.41-0/build.jl",
    # We need gettext
    "https://github.com/staticfloat/GettextBuilder/releases/download/v0.19.8-0/build.jl",
    # .....which needs libffi
    "https://github.com/staticfloat/libffiBuilder/releases/download/v3.2.1-0/build.jl",
    # .....which needs zlib
    "https://github.com/staticfloat/ZlibBuilder/releases/download/v1.2.11-3/build.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
