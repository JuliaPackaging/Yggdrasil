# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "jq"
version = v"1.7.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/stedolan/jq.git", "71c2ab509a8628dbbad4bc7b3f98a64aa90d3297")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jq
git submodule update --init
autoreconf -fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-oniguruma=builtin --disable-maintainer-mode
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("jq", :jq)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
