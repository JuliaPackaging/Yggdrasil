# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "S2Geometry"
version = v"0.14.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/s2geometry.git", "c24b368c67d0b8a2a109c5a75224e73a856bd8b7"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/s2geometry
# Upstream PR: https://github.com/google/s2geometry/pull/379
atomic_patch -p1 ../patches/msvc_to_win32_target.patch
mkdir build && cd build

# This release pins CMAKE_OSX_DEPLOYMENT_TARGET to 10.13 before project(), which
# lands in the cache before the toolchain file runs.  Seeding it here makes that
# `set(... CACHE ...)` a no-op, so MACOSX_DEPLOYMENT_TARGET still wins.
OSX_ARGS=()
if [[ "${target}" == *-apple-* ]]; then
    OSX_ARGS+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}")
fi

cmake "${OSX_ARGS[@]}" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTS=OFF \
    -DCMAKE_CXX_STANDARD=17 \
    ..
make -j${nproc}
make install
"""

# Abseil is built as C++17, and the libc++ in the default Intel macOS sys-root
# exports none of the std::bad_{variant,optional}_access symbols it needs.
sources, script = require_macos_sdk("10.14", sources, script)

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
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.16"),
    Dependency(PackageSpec(name="abseil_cpp_jll", uuid="43133aba-3931-5066-b004-a34c79b93f2e"); compat = "20250814.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Match S2Geography's compiler to preserve the MinGW C++ ABI across the DLL boundary.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version=v"10")
