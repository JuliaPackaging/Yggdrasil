# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cpu_features"
version = v"0.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/cpu_features/archive/refs/tags/v0.6.0.tar.gz", "95a1cf6f24948031df114798a97eea2a71143bd38a4d07d9a758dda3924c1932"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cpu_features-*/

if [[ ${target} == *-freebsd* ]]; then
    #this is not in 0.6.0 release, but has been added on master, can probably remove after next release
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/add-freebsd-macros.patch"
fi


mkdir build
cd build/

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental = true)


# The products that we will ensure are always built
products = [
    ExecutableProduct("list_cpu_features", :list_cpu_features)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
#need at least gcc5 for Wincompatible-pointer-type flag
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
