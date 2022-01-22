# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libfyaml"
version = v"0.7.12"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/pantoniou/libfyaml/releases/download/v$(version)/libfyaml-$(version).tar.gz",
                  "485342c6920e9fdc2addfe75e5c3e0381793f18b339ab7393c1b6edf78bf8ca8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libfyaml-*

# Replace `alloca.h` with `stdlib.h`
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/alloca.patch

./bootstrap.sh
./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --prefix=${prefix}
make -j${nproc}
make -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = filter(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfyaml", :libfyaml_c),

    ExecutableProduct("fy-compose", :fy_compose),
    ExecutableProduct("fy-dump", :fy_dump),
    ExecutableProduct("fy-filter", :fy_filter),
    ExecutableProduct("fy-join", :fy_join),
    ExecutableProduct("fy-testsuite", :fy_testsuite),
    ExecutableProduct("fy-tool", :fy_tool),
    ExecutableProduct("fy-ypath", :fy_ypath),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
