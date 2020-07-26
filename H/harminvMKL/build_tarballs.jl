# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "harminvMKL"
version = v"1.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/NanoComp/harminv.git", "b30436eccfdb2cf82aaba31db47ef3249f32dc5d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd harminv
# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
rm -f /opt/${MACHTYPE}/${MACHTYPE}/lib*/*.la
sh autogen.sh --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    MacOS(:x86_64),
    Linux(:x86_64, libc=:glibc)
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("harminv", :harminv)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MKL_jll", uuid="856f044c-d86e-5d09-b602-aeab76dc8ba7"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
