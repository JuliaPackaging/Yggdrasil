# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "cryptopp"
version = v"8.5"

# Collection of sources required to build cryptopp
sources = [
    GitSource("https://github.com/weidai11/cryptopp.git", "f2102243e6fdd48c0b2a393a0993cca228f20573"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cryptopp
# We need to fix the required glibc version.  They check that `getauxval` is available by
# checking the version of glibc (at least 2.16), but then they assume `AT_HWCAP2` is
# defined, which was introduced in glibc 2.18, which then sets a higher requirement than
# only having `getauxval`.
atomic_patch -p1 ../patches/powerpc-getauxval.patch
make -j${nproc} dynamic
make -j${nproc} install-lib PREFIX=${prefix}
if [[ "${target}" == *-mingw* ]]; then
    # The build system creates the shared library with the wrong name...
    mkdir -p "${libdir}"
    mv "${prefix}/lib/libcryptopp.so" "${libdir}/libcryptopp.${dlext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libcryptopp", :libcryptopp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6", lock_microarchitecture=false)
