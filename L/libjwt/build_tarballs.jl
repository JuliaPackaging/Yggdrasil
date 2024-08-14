# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libjwt"
version = v"1.15.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/benmcollins/libjwt.git", "e8af37ce2e7de2d3bbadaaf232dc6f6b0fd97f03")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libjwt
autoreconf -i
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libjwt", :libjwt),
    ExecutableProduct("jwtgen", :jwtgen),
    ExecutableProduct("jwtauth", :jwtauth)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
    Dependency(PackageSpec(name="Jansson_jll", uuid="83cbd138-b029-500a-bd82-26ec0fbaa0df"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
