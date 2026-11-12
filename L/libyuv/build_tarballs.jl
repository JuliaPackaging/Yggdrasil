# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "libyuv"
# This package doesn't have releases nor a version number
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://chromium.googlesource.com/libyuv/libyuv", "464c51a0353c71f08fe45f683d6a97a638d47833"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libyuv
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel ${nproc}

if [[ ${target} == *-w64-* ]]; then
    # The install process on Windows is broken; it doesn't know about the `.exe` suffix
    install -Dvm 755 build/yuvconvert.exe ${bindir}
    install -Dvm 755 build/libyuv.dll ${libdir}
    install -Dvm 755 build/libyuv.dll.a ${prefix}/lib
    install -Dvm 644 include/libyuv.h ${includedir}
    for file in $(cd include/libyuv && ls *.h); do
        install -Dvm 644 include/libyuv/${file} ${includedir}/libyuv/${file}
    done
else
    cmake --install build
    # Remove the static library (we don't need it)
    rm ${libdir}/libyuv.a
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libyuv", :libyuv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("JpegTurbo_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 6 for `nullptr`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
