# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QuEST"
version = v"3.5.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/QuEST-Kit/QuEST/archive/refs/tags/v$(version).tar.gz", "a3f6e30fddc6d4fef25d0338fcc234e0169309dddeff60344a257a3cb89775e2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/QuEST-3.5.0/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=-std=c99 ..
make
cp $WORKSPACE/srcdir/QuEST-3.5.0/QuEST/include/* ${prefix}/include/
cp $WORKSPACE/srcdir/QuEST-3.5.0/build/QuEST/libQuEST.so ${prefix}/lib/
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libQuEST", :libquest)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6"))
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
