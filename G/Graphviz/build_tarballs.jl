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
cd $WORKSPACE/srcdir
cd graphviz-2.40.1/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}

# For some reason the build wasn't able to pick up that the system provided a
# `sys/stat.h` file, so lib/sfio/sfsetbuf.c redefines `struct stat` which is an
# error. So we manually set the preprocessor macro definition to prevent that.
# (Presumably only some of the linux systems provide it, otherwise it wouldn't
# be configurable, so we probably need to enable this iff it's missing.)
if [[ "${target}" == *-linux* ]]; then  # TODO: figure out what this should be
    make CFLAGS="-D_sys_stat=1" -j${nproc}
else
    make -j${nproc}
fi

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
    PackageSpec(name="FreeType2_jll", uuid="d7e528f0-a631-5988-bf34-fe36492bcfd7")
    PackageSpec(name="Fontconfig_jll", uuid="a3f928ae-7b40-5064-980b-68af3947d34b")
    PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d")
    PackageSpec(name="Pango_jll", uuid="36c8627f-9965-5494-a995-c6b170f724f3")
    PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f")
    PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")
    PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

