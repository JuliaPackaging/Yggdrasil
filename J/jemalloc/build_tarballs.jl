# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "jemalloc"
version = v"5.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jemalloc/jemalloc.git", "54eaed1d8b56b1aa528be3bdd1877e59c56fa90c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jemalloc/
autoconf

FLAGS=(--disable-initial-exec-tls)
if [[ "${target}" == *-freebsd* ]]; then
     FLAGS+=(--with-jemalloc-prefix)
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libjemalloc", "jemalloc"], :libjemalloc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
