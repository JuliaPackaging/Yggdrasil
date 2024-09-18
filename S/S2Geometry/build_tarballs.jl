# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "S2Geometry"
version = v"0.11.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/s2geometry.git", "5b5eccd54a08ae03b4467e79ffbb076d0b5f221e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/s2geometry
# Upstream PR: https://github.com/google/s2geometry/pull/379
atomic_patch -p1 ../patches/msvc_to_win32_target.patch
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTS=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Only 64-bit platforms supported
filter!(p -> nbits(p) == 64, platforms)
# We are missing some dependencies (Abseil) for aarch64-freebsd, 
# can be re-enabled in the future when we have them
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
# Compilation fails for powerpc:
#     /workspace/srcdir/s2geometry/src/s2/s2edge_crossings.cc:120:31: error: ‘(6.15348059642740421245081038903225e-15l / 5.40431955284459475358983848622456e+16l)’ is not a constant expression
filter!(p -> arch(p) != "powerpc64le", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libs2", :libs2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.15"),
    Dependency(PackageSpec(name="abseil_cpp_jll", uuid="43133aba-3931-5066-b004-a34c79b93f2e"); compat = "20240116.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version=v"7")
