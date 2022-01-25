# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "UDUNITS"
version = v"2.2.28"

# Collection of sources required to complete build
sources = [
    # .tar.gz archive is missing cmake files: https://github.com/Unidata/UDUNITS-2/issues/108
    ArchiveSource("https://artifacts.unidata.ucar.edu/repository/downloads-udunits/udunits-$(version).zip",
                  "e09d31db68f9a840a0663c7e9909101957733ff0310761b9906f4722e0d92c44"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
apk add --upgrade cmake --repository=http://dl-cdn.alpinelinux.org/alpine/v3.14/main # requires CMake 3.19

cd $WORKSPACE/srcdir/udunits-*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/freebsd.patch

mkdir build
cd build

cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libudunits2", :libudunits2),
    ExecutableProduct("udunits2", :udunits2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"); compat="2.2.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
