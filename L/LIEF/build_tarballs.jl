# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LIEF"
version = v"0.17.6"

# Collection of sources required to complete build.
# The LIEF repository vendors all of its third-party dependencies (mbedtls,
# spdlog, nlohmann/json, frozen, expected, utfcpp, tcb/span) as zip archives
# under `third-party/`, and `THIRD_PARTY_DIRECTORY` defaults to that path, so the
# build is fully offline with no extra dependencies.
sources = [
    GitSource("https://github.com/lief-project/LIEF.git",
              "6f3594f27056b85df51d6ad1c4ca944840ad3612"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LIEF

# The CMake shipped in the rootfs is too old (LIEF requires >= 3.24), so remove
# it and use the newer one provided by CMake_jll (HostBuildDependency).
apk del cmake

cmake -B build -GNinja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLIEF_C_API=ON \
    -DLIEF_PYTHON_API=OFF \
    -DLIEF_EXAMPLES=OFF \
    -DLIEF_TESTS=OFF \
    -DLIEF_DOC=OFF \
    -DLIEF_USE_CCACHE=OFF \
    -DLIEF_INSTALL=ON
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# LIEF's upstream CI covers Linux, macOS and Windows.  BinaryBuilder builds
# Windows with mingw-w64 (LIEF upstream targets MSVC), and FreeBSD is untested
# upstream, so we build for Linux, macOS and Windows here.
platforms = supported_platforms()
filter!(p -> os(p) in ("linux", "macos", "windows"), platforms)

# LIEF is a C++ library that exports C++ symbols (using std::string) alongside
# its C API, so we expand the C++ string ABIs.
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built.
# The C API is compiled into the libLIEF shared library when LIEF_C_API=ON.
products = [
    LibraryProduct("libLIEF", :libLIEF),
]

# Dependencies that must be installed before this package can be built.
# (LIEF vendors all of its third-party dependencies; we only need a newer CMake
# than the one in the rootfs.)
dependencies = [
    # LIEF requires CMake >= 3.24, newer than the rootfs default.  The
    # "3.24 - 3" VersionSpec means ">= 3.24, < 4" so the resolver still picks
    # the latest 3.x (pinning to exactly 3.24.x pulls in an incompatible
    # OpenSSL_jll).
    HostBuildDependency(PackageSpec(; name="CMake_jll", version="3.24 - 3")),
]

# Build the tarballs, and possibly a `build.jl` as well.
# LIEF requires a C++17 compiler and CMake >= 3.24.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
