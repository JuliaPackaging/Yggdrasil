# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libxc"
version = v"5.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.com/libxc/libxc/-/archive/$(version)/libxc-$(version).tar.gz",
                  "e8d2b6eb2b46b356a27f0367a7665ff276d7f295da7c734e774ee66f82e56297"),
]

# Bash recipe for building across all platforms
# Notes:
#   - Autotools fully supported upstream, but Windows builds only work with CMake
#   - 3rd and 4th derivatives (KXC, LXC) not built since gives a binary size of ~200MB
script = raw"""
cd $WORKSPACE/srcdir/libxc-*/

if [[ "${target}" = *-mingw* ]]; then
    mkdir libxc_build
    cd libxc_build
    cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release -DENABLE_FORTRAN=OFF -DENABLE_XHOST=OFF -DBUILD_SHARED_LIBS=ON \
        -DDISABLE_VXC=OFF -DDISABLE_FXC=OFF -DDISABLE_KXC=ON -DDISABLE_LXC=ON ..
else
    autoreconf -vi
    export CFLAGS="$CFLAGS -std=c99"
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-fortran \
        --disable-static --enable-shared \
        --enable-vxc=yes --enable-fxc=yes --enable-kxc=no --enable-lxc=no
fi

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Disable armv7l because the build seems to fill /tmp.
platforms = [p for p in supported_platforms() if arch(p) != :armv7l]


# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
