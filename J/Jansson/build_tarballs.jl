using BinaryBuilder

name = "Jansson"
version = v"2.14"

# Collection of sources required to build ZMQ
sources = [
    GitSource("https://github.com/akheron/jansson.git", "684e18c927e89615c2d501737e90018f4930d6c5"),
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
