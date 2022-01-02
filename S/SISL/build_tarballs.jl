# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SISL"
version = v"4.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/SINTEF-Geometry/SISL/archive/refs/tags/SISL-$(version).tar.gz", "b207fe6b4b20775e3064168633256fddd475ff98573408f6f5088a938c086f86"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SISL-*

if [[ "${target}" == *-mingw* ]]; then
    #this is derived directly from https://github.com/SINTEF-Geometry/SISL/pull/6, if that ever get merged this can be removed
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-cmake-patch.patch
fi

mkdir build
cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-Dsisl_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=ON

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental = true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libsisl", :libsisl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
