# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NativeFileDialog"
version = v"1.1.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mlabbe/nativefiledialog.git", "2850c97af02e6b4cce6ffb91a0445acb5eb9b241"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nativefiledialog/src/
mkdir -p "${libdir}"
if [[ "${target}" == *-mingw* ]]; then
    c++ nfd_common.c nfd_win.cpp -DNDEBUG -DUNICODE -D_UNICODE -lole32 -luuid -Iinclude -O2 -Wall -Wextra -fno-exceptions -shared -o "${libdir}/libnfd.${dlext}"
elif [[ "${target}" == *-apple* ]]; then
    cc nfd_cocoa.m nfd_common.c -DNDEBUG -framework Foundation -framework AppKit -Iinclude -O2 -Wall -Wextra -fno-exceptions -fPIC -shared -o "${libdir}/libnfd.${dlext}"
elif [[ "${target}" == *-linux-* && "${nbits}" == 32 ]]; then
    # patch for old gcc in 32bit linux and other for musl
    atomic_patch -p2 ../../patches/32bit-linux-fix.diff
    cc nfd_common.c nfd_gtk.c -D_FILE_OFFSET_BITS=64 -DNDEBUG -Iinclude `pkg-config --cflags --libs gtk+-3.0` -O2 -Wall -Wextra -fno-exceptions -fPIC -shared -o "${libdir}/libnfd.${dlext}"
else
    cc nfd_common.c nfd_gtk.c -DNDEBUG -Iinclude `pkg-config --cflags --libs gtk+-3.0` -O2 -Wall -Wextra -fno-exceptions -fPIC -shared -o "${libdir}/libnfd.${dlext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libnfd", :libnfd)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GTK3_jll"; platforms=filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms))
    BuildDependency("Xorg_xorgproto_jll"; platforms=filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
