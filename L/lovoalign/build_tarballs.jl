# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lovoalign"
version = v"20.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/m3g/lovoalign.git", "1e53ba4861e771d20cc081ee2be511130e606da4"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd lovoalign/src
if [[ $target == *"w64-mingw32" ]]; then
    sed -i 's/lblastrampoline/lblastrampoline-5/' Makefile
fi
make
cp ../bin/lovoalign ../../../destdir
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("lovoalign", :lovoalign)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
