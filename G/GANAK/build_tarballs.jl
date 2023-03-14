# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GANAK"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/meelgroup/ganak.git", "36fa4b35c8e3cb588a3a76a87624d97ae7f18285")
]

# Bash recipe for building across all platforms
script = raw"""
cd ganak/
mkdir build; cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} ..
make
install -c ganak -Dt $bindir 
install -c src/libganak.so.1.0 -Dt $libdir
ln -s $libdir/libganak.so.1.0 $libdir/libganak.so
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("ganak", :ganak)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
    Dependency(PackageSpec(name="MPC_jll", uuid="2ce0c516-f11f-5db3-98ad-e0e1048fbd70"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
