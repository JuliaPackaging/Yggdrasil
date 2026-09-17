using BinaryBuilder, Pkg

name = "Fparser"
version = v"4.5.1"

# ---------------------------------------------------------------------------
# Sources
# thliebig's fork of the fparser library (warp.povusers.org/FunctionParser),
# maintained as a git repository and used as a submodule by openEMS-Project.
# ---------------------------------------------------------------------------
sources = [
    GitSource(
        "https://github.com/thliebig/fparser.git",
        "ee15c675514e53b37304179b4a91319d44ba9a85",  # master HEAD (no release tags)
    ),
]

# ---------------------------------------------------------------------------
# Build script
# ---------------------------------------------------------------------------
script = raw"""
cd ${WORKSPACE}/srcdir/fparser

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build

install_license ${WORKSPACE}/srcdir/fparser/docs/lgpl.txt
"""

# ---------------------------------------------------------------------------
# Platforms
# ---------------------------------------------------------------------------
platforms = expand_cxxstring_abis(supported_platforms())

# ---------------------------------------------------------------------------
# Products
# ---------------------------------------------------------------------------
products = [
    LibraryProduct("libfparser", :libfparser),
]

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------
dependencies = Dependency[]

build_tarballs(
    ARGS,
    name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"9",
)
