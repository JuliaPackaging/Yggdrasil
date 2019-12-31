# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Graphviz"
version = v"2.40.1"

# Collection of sources required to complete build
sources = [
    "https://graphviz.gitlab.io/pub/graphviz/stable/SOURCES/graphviz.tar.gz" =>
    "ca5218fade0204d59947126c38439f432853543b0818d9d728c589dfe7f3a421",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphviz-*/

if [[ "${target}" == *-linux-* ]]; then
    # For some reason the build wasn't able to pick up that the system provided a
    # `sys/stat.h` file, so lib/sfio/sfsetbuf.c redefines `struct stat` which is an
    # error. So we manually set the preprocessor macro definition to prevent that.
    # (Presumably only some of the linux systems provide it, otherwise it wouldn't
    # be configurable, so we probably need to enable this iff it's missing.)
    export CFLAGS="-D_sys_stat=1"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = [
#    Linux(:i686, libc=:glibc),
#    Linux(:x86_64, libc=:glibc),
#    Linux(:i686, libc=:musl),
#    Linux(:x86_64, libc=:musl)
#]   # these are the only ones that worked in the Wizard so far.
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    ExecutableProduct("gvpr", :gvpr),
    ExecutableProduct("dot", :dot)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a")
    PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201")
    PackageSpec(name="Pango_jll", uuid="36c8627f-9965-5494-a995-c6b170f724f3")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
