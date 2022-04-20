
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Vulkan_Volk"
version = v"1.3.204"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/zeux/volk/archive/refs/tags/$(version).tar.gz",
                  "7776e7f3c70f199579da33d2ccd7152ca8b96182fa98c31fbe80880cef0fdf70")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/volk*/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DVOLK_INSTALL=ON \
    -S .. \
    -B .
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

products = [
    FileProduct("include/volk.h", :volk_h),
    FileProduct("lib/libvolk.a", :libvolk),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Vulkan_Headers_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
