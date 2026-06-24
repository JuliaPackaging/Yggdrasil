# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lexbor"
version = v"2.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lexbor/lexbor.git", "e01ece21c216a1ef0147cefcd77782d2d25d7d4a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lexbor
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DLEXBOR_BUILD_SEPARATELY=ON \
    -DLEXBOR_BUILD_STATIC=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblexbor-dom", :liblexbor_dom),
    LibraryProduct("liblexbor-tag", :liblexbor_tag),
    LibraryProduct("liblexbor-url", :liblexbor_url),
    LibraryProduct("liblexbor-unicode", :liblexbor_unicode),
    LibraryProduct("liblexbor-css", :liblexbor_css),
    LibraryProduct("liblexbor", :liblexbor),
    LibraryProduct("liblexbor-ns", :liblexbor_ns),
    LibraryProduct("liblexbor-encoding", :liblexbor_encoding),
    LibraryProduct("liblexbor-core", :liblexbor_core),
    LibraryProduct("liblexbor-selectors", :liblexbor_selectors),
    LibraryProduct("liblexbor-utils", :liblexbor_utils),
    LibraryProduct("liblexbor-punycode", :liblexbor_punycode),
    LibraryProduct("liblexbor-html", :liblexbor_html)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
