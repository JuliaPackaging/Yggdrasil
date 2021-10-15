# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NativeFileDialog"
version = v"1.1.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mlabbe/nativefiledialog.git", "67345b80ebb429ecc2aeda94c478b3bcc5f7888e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nativefiledialog/src/
if [[ "${target}" == *-mingw* ]]; then
    c++ nfd_common.c nfd_win.cpp -lole32 -luuid -Iinclude -O2 -Wall -Wextra -fno-exceptions -shared -o "${libdir}/libnfd.${dlext}"
elif [[ "${target}" == *-apple* ]]; then
    cc nfd_cocoa.m nfd_common.c -framework Foundation -framework AppKit -Iinclude -O2 -Wall -Wextra -fno-exceptions -fPIC -shared -o "${libdir}/libnfd.${dlext}"
else
    cc nfd_common.c nfd_gtk.c -Iinclude `pkg-config --cflags --libs gtk+-3.0` -O2 -Wall -Wextra -fno-exceptions -fPIC -shared -o "${libdir}/libnfd.${dlext}"
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
    Dependency(PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6"))
    BuildDependency("Xorg_xorgproto_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
