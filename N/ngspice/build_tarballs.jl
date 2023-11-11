# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ngspice"
version = v"41"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/imr/ngspice.git", "2275fb85da31a8c802ebf9730935c8c00d6cdea0"), #ngspice git mirror
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
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ac_cv_func_malloc_0_nonnull=yes --enable-cider --enable-osdi --with-ngshared ac_cv_func_realloc_0_nonnull=yes
make -j${nproc}
make install
# Build executable version
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ac_cv_func_malloc_0_nonnull=yes --enable-cider --enable-osdi ac_cv_func_realloc_0_nonnull=yes
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
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
