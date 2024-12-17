# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GTPSA"
version = v"1.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mattsignorelli/gtpsa.git", "c46ebfcd28e8976f7d02b63a1c73cd685c45d318")
]

# Bash recipe for building across all platforms
# GCC >=11 is necessary because the source code uses the two-argument version
# of the attribute malloc, see https://github.com/mattsignorelli/gtpsa/blob/394a20847b869a842c6a89f2af1a889c3a1c2813/code/mad_mem.h#L73-L75 (also unsupported by clang)
script = raw"""
cd $WORKSPACE/srcdir
cd gtpsa/
cmake . -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# The code does not compile on FreeBSD due to an error with __builtin_tgmath
platforms = supported_platforms()
filter!(!Sys.isfreebsd, platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libgtpsa", :GTPSA)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")
