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
cd $WORKSPACE/srcdir
cd jemalloc/
autoconf

if [[ "${target}" == "x86_64-linux-gnu" ]]; then
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-initial-exec-tls
elif [[ "${target}" == *-freebsd* ]]; then
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-jemalloc-prefix
else
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
fi

make
make install

# Rename .dll for Windows targets.
if [[ "${target}" == *"w64"* ]]; then
    mkdir -p ${libdir}
    mv ${prefix}/lib/jemalloc.dll ${libdir}/libjemalloc.dll
fi

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjemalloc", :libjemalloc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
