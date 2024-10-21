# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MEOS"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/MobilityDB/MobilityDB.git", "60048b5b4b7ce2f7560c024d1af024db73b3bd5b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/MobilityDB

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DMEOS=ON \
    -DHAVE_X86_64_POPCNTQ_EXITCODE="FAILED_TO_RUN" \
    -DHAVE_X86_64_POPCNTQ_EXITCODE__TRYRUN_OUTPUT=
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
filter!(x -> arch(x) != "i686", platforms)  # __int128 not supported on i686
filter!(x -> !startswith(arch(x), "armv"), platforms)  # __int128 not supported on armv
filter!(!=(Platform("aarch64", "freebsd")), platforms)  # Misses most dependencies

# The products that we will ensure are always built
products = [
    LibraryProduct("libmeos", :libmeos)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GEOS_jll", uuid="d604d12d-fa86-5845-992e-78dc15976526"))
    Dependency(PackageSpec(name="JSON_C_jll", uuid="9cdfc4e7-e793-5089-b6f7-569a57a60f0a"))
    Dependency(PackageSpec(name="PROJ_jll", uuid="58948b4f-47e0-5654-a9ad-f609743f8632"))
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
