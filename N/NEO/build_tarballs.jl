# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NEO"
version = v"22.53.25242"#.13

# Collection of sources required to build this package.
sources = [
    GitSource("https://github.com/intel/compute-runtime.git",
              "d9a4eeea8900fa32a45212cdc72293592295159f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd compute-runtime
install_license LICENSE.md

# work around compilation failures
## already defined in gmmlib
sed -i '/__stdcall/d' shared/source/gmm_helper/gmm_lib.h
## extend LD_LIBRARY_PATH, don't overwrite it
find . \( -name CMakeLists.txt -or -name '*.cmake' \) -exec \
    sed -i 's/LD_LIBRARY_PATH=/LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}:/g' '{}' \;
## NO
sed -i '/-Werror/d' CMakeLists.txt

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

# we don't care about cl_intel_va_api_media_sharing
CMAKE_FLAGS+=(-DDISABLE_LIBVA:Bool=true)

# enable support for the DG1
CMAKE_FLAGS+=(-DSUPPORT_DG1:Bool=true)

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
    Platform("x86_64", "linux", libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("ocloc", :ocloc),
    LibraryProduct("libigdrcl", :libigdrcl, ["lib/intel-opencl", "lib64/intel-opencl"]),
    LibraryProduct("libze_intel_gpu", :libze_intel_gpu),
]

# Dependencies that must be installed before this package can be built
# NOTE: these hashes are taken from the release notes in GitHub,
#       https://github.com/intel/compute-runtime/releases.
#       when using a non-public release, refer to the compiled manifest
#       https://github.com/intel/compute-runtime/blob/master/manifests/manifest.yml.
dependencies = [
    Dependency("gmmlib_jll"; compat="=22.3.0"),
    Dependency("libigc_jll"; compat="=1.0.12812"),
    Dependency("oneAPI_Level_Zero_Headers_jll", v"1.4.8"; compat="1.3.7"),
]

# GCC 4 has constexpr incompatibilities
# GCC 7 triggers: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=79929
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8")
