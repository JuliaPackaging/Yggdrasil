# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tblis"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/devinamatthews/tblis.git", "3e4c4b82943726c443b6f408c9c9791dcad7a847")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd tblis/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
cp lib/.libs/libtblis.so.0.0.0 ${libdir}/libtblis.so.0
cp src/external/tci/lib/.libs/libtci.so.0.0.0 ${libdir}/libtci.so.0
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    Linux(:x86_64, libc=:musl)
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libtci", :tci),
    LibraryProduct("libtblis", :tblis)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
