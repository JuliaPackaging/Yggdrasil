using BinaryBuilder

name = "Jansson"
version = v"2.14.1"

# Collection of sources required to build Jansson
sources = [
    GitSource("https://github.com/akheron/jansson.git", "ed5cae4ed0621ef409510f94270c9f8f263736d0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jansson

autoreconf -fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libjansson", :libjansson),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
