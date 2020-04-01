# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libxc"
version = v"4.3.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.com/libxc/libxc/-/archive/4.3.4/libxc-4.3.4.tar.gz",
                  "2d5878dd69f0fb68c5e97f46426581eed2226d1d86e3080f9aa99af604c65647"),
]

# Bash recipe for building across all platforms
# Note: Autotools fully supported upstream, but Windows builds only work with CMake
script = raw"""
cd $WORKSPACE/srcdir/libxc-*/

if [[ "${target}" = *-mingw* ]]; then
    mkdir libxc_build
    cd libxc_build
    cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release -DENABLE_FORTRAN=OFF -DBUILD_SHARED_LIBS=ON \
        -DENABLE_XHOST=OFF ..
else
    autoreconf -vi
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared --disable-fortran
fi

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
