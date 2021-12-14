# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "jemalloc"
version = v"5.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jemalloc/jemalloc.git", "886e40bb339ec1358a5ff2a52fdb782ca66461cb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jemalloc/
autoconf

if [[ "${target}" == *-freebsd* ]]; then
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-initial-exec-tls --with-jemalloc-prefix
else
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-initial-exec-tls
fi

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libjemalloc", "jemalloc"], :libjemalloc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
