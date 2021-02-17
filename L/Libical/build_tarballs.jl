# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libical"
version = v"3.0.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libical/libical/releases/download/v3.0.9/libical-3.0.9.tar.gz", "bd26d98b7fcb2eb0cd5461747bbb02024ebe38e293ca53a7dfdcb2505265a728")
]

# Bash recipe for building across all platforms
script = raw"""
cd libical-*
apk add doxygen
apk add gtk-doc
# apparently cross compiling libical requires a binary from the native build? specified as a cmake argument below
mkdir native_build
# I stole this idea from the ICU build script, no idea if I did it right
(
    CC="${CC_BUILD}"
    CXX="${CXX_BUILD}"
    cmake -B native_build
)
cd native_build
make
make install
cd ..
mkdir build
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DIMPORT_ICAL_GLIB_SRC_GENERATOR="${PWD}/native_build/bin/ical-glib-src-generator"
cd build
make
make install
cd ..
rm -r native_build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    # TBD
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GLib_jll"),
    Dependency("XML2_jll"),
    Dependency("ICU_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
