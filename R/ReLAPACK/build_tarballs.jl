# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ReLAPACK"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/HPAC/ReLAPACK.git", "de3317cdd5677f157bfd7f4a614c7f67ffaeff0d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd ReLAPACK
make
cd src/
${CC} -shared -o librelapack.${dlext} *.o -lblastrampoline -lm
mv librelapack.${dlext} ${libdir}
mv ../inc/relapack.h ${includedir}
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("librelapack", :librelapack)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8")
