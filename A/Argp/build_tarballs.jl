# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Argp"
version = v"1.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ericonr/argp-standalone.git", "743004c68e7358fb9cd4737450f2d9a34076aadf"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/argp-standalone

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

autoreconf -i
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}
make CC=gcc
install -Dvm 644 argp.h -t $includedir
install -Dvm 644 libargp.a -t $libdir

install_license ${WORKSPACE}/srcdir/argp-standalone/README.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    # argp is meant as a build-time dependency to be included in other recipes, so static library only
    LibraryProduct("libargp.a", :libargp),
    FileProduct("include/argp.h", :argp_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
