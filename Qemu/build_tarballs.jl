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

./configure --host-cc="${HOSTCC}" --extra-cflags="-I${prefix}/include" --disable-cocoa --prefix=$prefix

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
    Linux(:x86_64),
    MacOS(),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "x86_64-softmmu/qemu-system-x86_64", :qemu_x86_64)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need Pixman
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Pixman-v0.36.0-0/build_Pixman.v0.36.0.jl",
    # We need Glib
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Glib-v2.59.0-0/build_Glib.v2.59.0.jl",
    # We need Pcre
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/PCRE-v8.42-2/build_PCRE.v8.42.0.jl",
    # We need gettext
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Gettext-v0.19.8-0/build_Gettext.v0.19.8.jl",
    # .....which needs libffi and iconv
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libffi-v3.2.1-0/build_Libffi.v3.2.1.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libiconv-v1.15-0/build_Libiconv.v1.15.0.jl",
    # .....which needs zlib
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.3/build_Zlib.v1.2.11.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
