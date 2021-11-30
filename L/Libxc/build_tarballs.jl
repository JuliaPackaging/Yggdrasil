# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libxc"
version = v"5.1.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.com/libxc/libxc/-/archive/$(version)/libxc-$(version).tar.gz",
                  "2d82b7bcfd8749490f6bb0906acf99fbf03050696dd2213da4b7a7600fc14328"),
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
        -DCMAKE_BUILD_TYPE=Release -DENABLE_FORTRAN=ON -DENABLE_XHOST=OFF -DBUILD_SHARED_LIBS=ON \
        -DDISABLE_VXC=OFF -DDISABLE_FXC=OFF -DDISABLE_KXC=ON -DDISABLE_LXC=ON ..
else
    autoreconf -vi
    export CFLAGS="$CFLAGS -std=c99"
    export FCFLAGS="-pipe -O3"
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
        --disable-static --enable-shared \
        --enable-vxc=yes --enable-fxc=yes --enable-kxc=no --enable-lxc=no
fi

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms(; experimental=true))


# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5", julia_compat="1.6")
