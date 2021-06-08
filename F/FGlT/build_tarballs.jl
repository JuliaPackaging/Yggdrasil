# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FGlT"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fcdimitr/fglt.git", "c3c0c683a76fef56473314527760b74ffd271455")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd fglt/
if [[ "${target}" == *-i686* ]] || [[ "${target}" == *-armv7l-linux-musl* ]] || [[ "${target}" == *-x86_64-linux-musl* ]] || [[ "${target}" == *-x86_64-linux-gnu* ]]; then
  meson --cross-file=${MESON_TARGET_TOOLCHAIN} -Dprefer_openmp=true build
else
  meson --cross-file=${MESON_TARGET_TOOLCHAIN} build
fi
cd build/
ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# [FIXED!] FGlT contains std::string values!  This causes incompatibilities across the GCC 4/5 version boundary.
# platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfglt", :libfglt)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")  # CILK support
