# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ngspice"
version = v"32.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/imr/ngspice.git", "a0389bb5471a43bc828b08b81bd3fc1693200130"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ngspice
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
LIBTOOLIZE=libtoolize ./autogen.sh
# Build shared library version
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ac_cv_func_malloc_0_nonnull=yes --enable-cider --with-ngshared ac_cv_func_realloc_0_nonnull=yes
make -j${nproc}
make install
# Build executable version
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ac_cv_func_malloc_0_nonnull=yes --enable-cider ac_cv_func_realloc_0_nonnull=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("ngspice", :ngspice),
    LibraryProduct("libngspice", :libngspice)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
