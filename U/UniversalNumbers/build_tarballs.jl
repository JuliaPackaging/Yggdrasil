# BinaryBuilder recipe for UniversalNumbers_jll
#
# Produces a pre-built libuniversal shared library for all supported platforms.
# The resulting JLL package is what lets users `] add UniversalNumbers` without
# needing a local C++ toolchain.
#
# --- Workflow ---
#
# 1. Tag and push the release:
#      git tag -a v0.1.0 -m "v0.1.0"
#      git push origin v0.1.0
#
# 2. Get the commit SHA the tag points to:
#      git rev-parse v0.1.0^{}
#
# 3. Replace the placeholder SHA below with that output.
#
# 4. Test locally (requires BinaryBuilder in global env):
#      julia build_tarballs.jl --verbose x86_64-linux-gnu
#
# 5. Submit to Yggdrasil:
#      - Fork https://github.com/JuliaPackaging/Yggdrasil
#      - Add this file at  Y/UniversalNumbers/build_tarballs.jl
#      - Open a PR; CI builds all platforms and auto-publishes UniversalNumbers_jll

using BinaryBuilder, Pkg

name    = "UniversalNumbers"
version = v"0.1.0"

# ---------------------------------------------------------------------------
# Source
# ---------------------------------------------------------------------------
# The Julia package repo ships the C++ wrapper and vendored Stillwater
# Universal headers under deps/universal/include/sw -- no external dependencies.
sources = [
    GitSource(
        "https://github.com/jamesquinlan/UniversalNumbers.jl.git",
        "1bbd5c45e9647af037b13a5b923a5532b1254c6a",   # run: git rev-parse v0.1.0^{}
    ),
]

# ---------------------------------------------------------------------------
# Build script (runs inside the BinaryBuilder sandbox)
# ---------------------------------------------------------------------------
script = raw"""
cd ${WORKSPACE}/srcdir/UniversalNumbers.jl
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel ${nproc}
cmake --install build
"""

# ---------------------------------------------------------------------------
# Target platforms
# ---------------------------------------------------------------------------
# The public API is pure extern "C", but the compiled library still contains
# internal std::string symbols (printbits / Universal manipulators), so the
# auditor requires building both libstdc++ string ABIs.  Windows uses MinGW-w64
# which supports __uint128_t (used by dd).
platforms = [
    Platform("x86_64",  "linux";   libc = "glibc"),
    Platform("aarch64", "linux";   libc = "glibc"),
    Platform("x86_64",  "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64",  "windows"),
]

# Internal std::string symbols -> build for both C++ string ABIs (cxx03 + cxx11).
platforms = expand_cxxstring_abis(platforms)

# ---------------------------------------------------------------------------
# Products
# ---------------------------------------------------------------------------
products = [
    LibraryProduct("libuniversal", :libuniversal),
]

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------
# Stillwater Universal headers are vendored in deps/.  The compiled library links
# the GCC runtime (libgcc_s), provided by CompilerSupportLibraries_jll.
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# ---------------------------------------------------------------------------
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat        = "1.9",
               preferred_gcc_version = v"13")
