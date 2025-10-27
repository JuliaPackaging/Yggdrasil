# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "f4ncgb"
version = v"0.3.2"

sources = [
    GitSource("https://gitlab.sai.jku.at/f4ncgb/f4ncgb.git",
              "34131635fcef568f2a426cb00f1777433e7b5a56"),
    ArchiveSource("https://github.com/joseluisq/MacOSX-SDKs/releases/download/15.0/MacOSX15.0.sdk.tar.xz",
                  "9df0293776fdc8a2060281faef929bf2fe1874c1f9368993e7a4ef87b1207f98"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-apple-darwin* ]]; then
    # Install a newer SDK which supports C++20
    # including std::format and concepts... which were added even later than c++20 support
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX15.0.sdk
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    export MACOSX_DEPLOYMENT_TARGET=15.0
fi

cd ${WORKSPACE}/srcdir/f4ncgb

# no march=native, no test binary
extraflags="-DENABLE_NATIVE=OFF -DENABLE_TEST=OFF"

if [[ "${target}" == *-mingw* ]]; then
   # profiling needs sys/resource.h
   # no proper signal handling for windows
   extraflags="$extraflags -DENABLE_PROFILING=OFF -DENABLE_SIGNAL=OFF"
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DSHARED_LIB=ON \
    $extraflags \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc} -t install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# 32bit architectures are not supported
filter!(p -> nbits(p) != 32, platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("f4ncgb", :f4ncgb)
    LibraryProduct("libf4ncgb", :libf4ncgb)
]



# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
    Dependency("MPFR_jll", v"4.2.0"),
    Dependency("FLINT_jll", compat = "~301.300.101"),
    Dependency("boost_jll", compat = "=1.87.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc 13 is needed for std::format and thus we cannot dlopen during audit
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10",
               preferred_gcc_version=v"13",
               dont_dlopen=true)
