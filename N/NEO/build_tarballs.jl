# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NEO"
version = v"20.24.17065"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/intel/compute-runtime.git",
              "22076663e44135e6b7a83ad3ccd76d8a100a78ed"),
    # vendored dependencies
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "ebb363e938a279cf866cb93d28e31aaf0791ea19"),  # v0.91.10
]

# Bash recipe for building across all platforms
script = raw"""
# NEO builds against a very specific version of the oneL0 specification headers,
# so we can't use regular (Build)Dependencies.
mv level-zero level_zero

cd compute-runtime
install_license LICENSE

# work around compilation failures
## already defined in gmmlib
sed -i '/__stdcall/d' shared/source/gmm_helper/gmm_lib.h
## extend LD_LIBRARY_PATH, don't overwrite it
find . \( -name CMakeLists.txt -or -name '*.cmake' \) -exec \
    sed -i 's/LD_LIBRARY_PATH=/LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}:/g' '{}' \;

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# NOTE: NEO currently can't cross compile because of its IGC dependency
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=OFF)

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Don't run tests
CMAKE_FLAGS+=(-DSKIP_UNIT_TESTS:Bool=true)

# libigc installs libraries and pkgconfig rules in lib64, so look for them there.
# FIXME: shouldn't BinaryBuilder do this?
export PKG_CONFIG_PATH=${prefix}/lib64/pkgconfig:${prefix}/lib/pkgconfig

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # NEO is 64-bit only: https://github.com/intel/compute-runtime/issues/179
    # and does not support musl: https://github.com/intel/compute-runtime/issues/265
    Linux(:x86_64, libc=:glibc),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("ocloc", :ocloc),
    LibraryProduct("libigdrcl", :libigdrcl, ["lib/intel-opencl", "lib64/intel-opencl"]),
    LibraryProduct("libze_intel_gpu", :libze_intel_gpu),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="gmmlib_jll", version=v"20.1.1")),
    Dependency(PackageSpec(name="libigc_jll", version=v"1.0.4154")),
    # TODO: reverse compatibility bounds, where NEO (providing a oneL0 impl of, e.g., v0.91)
    #       restricts oneAPI_Level_Zero_jll to be below that version too.
]

# GCC 4 has constexpr incompatibilities
# GCC 7 triggers: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=79929
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8")
