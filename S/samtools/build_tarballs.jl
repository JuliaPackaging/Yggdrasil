# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "samtools"
version = v"1.19.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/samtools/samtools.git", "66830a3178c7dca941ec0f3b699477464bd44b76"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/samtools/
autoheader
autoconf -Wno-syntax
if [[ "${target}" == x86_64-linux-musl ]]; then
    # Need to pass `-lcurl -lnghttp2` because it's needed by libhts
    # TODO: find a way to avoid this.
    export LIBS="-lcurl -lnghttp2"
elif [[ "${target}" == *-freebsd* ]]; then
     export CPPFLAGS="-I${includedir}"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("samtools", :samtools)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a"))
    Dependency(PackageSpec(name="htslib_jll", uuid="f06fe41e-9474-5571-8c61-5634d2b2700c"); compat="1.19.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # Note: for some reason GCC 4.8 is still linked to glibc 2.12, we
               # need to use at least GCC 5 to have glibc 2.17.
               julia_compat="1.6", preferred_gcc_version=v"6")
