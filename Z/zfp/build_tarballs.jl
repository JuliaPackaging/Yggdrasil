# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "zfp"
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/LLNL/zfp/releases/download/$(version)/zfp-$(version).tar.gz",
                  "ca0f7b4ae88044ffdda12faead30723fe83dd8f5bb0db74125df84589e60e52b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zfp-*
mkdir build && cd build/
if [[ "${target}" == *-freebsd* ]]; then
    # Give a hint to the linker to explicitly use `-lm`
    export LDFLAGS="-lm"
fi
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libzfp", :libzfp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
