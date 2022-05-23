# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Doxygen"
version = v"1.9.2"

# Notes
# - compile error on g++ < 8

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/doxygen/doxygen/archive/refs/tags/Release_$(version.major)_$(version.minor)_$(version.patch).tar.gz",
                  "40f429241027ea60f978f730229d22e971786172fdb4dc74db6406e7f6c034b3"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/doxygen*/
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 ../patches/skip-iconv-in-glibc-test.patch
fi
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install

install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("doxygen", :doxygen),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libiconv_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"8")
