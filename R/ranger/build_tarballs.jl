# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ranger"
version = v"0.13.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/imbs-hl/ranger/archive/refs/tags/v$(version).tar.gz", "de60c5ca6ffab1b6cd17c8058c7736f74944841d782707906ba3c68530688916"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ranger*/cpp_version/
atomic_patch -p2 ${WORKSPACE}/srcdir/patches/make_lib_and_install.patch
atomic_patch -p2 ${WORKSPACE}/srcdir/patches/cmake-pthreads.patch
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIB=1 \
    ..
make -j$nproc
make install
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libranger", :libranger)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
