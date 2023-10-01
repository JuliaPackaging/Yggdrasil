# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libmonitor"
version = v"2023.03.15"

# Collection of sources required to build hwloc
sources = [
    GitSource("https://github.com/HPCToolkit/libmonitor.git", "48520940b915352748950ea718fadc82f87f659d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libmonitor
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-client-signals=SIGBUS,SIGSEGV,SIGPROF,36,37,38 \
    --disable-dlfcn
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmonitor", :libmonitor),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
