# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gmsh"
version = v"4.8.1"

# Collection of sources required to build Gmsh
sources = [
    ArchiveSource("https://gmsh.info/src/gmsh-$version-source.tgz", "d5038f5f25ae85973536fb05cc886feb1bd7d67e2605a9d8789bcc2528fa8b35")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gmsh-4.8.1-source
install_license LICENSE.txt
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_BUILD_DYNAMIC=1 \
      ..
make -j${nproc}
make install
mv ${prefix}/lib/gmsh.jl ${prefix}/lib/gmsh.jl.bak
sed ${prefix}/lib/gmsh.jl.bak \
  -e 's/^\(import Libdl\)/#\1/g' \
  -e 's/^\(const lib.*\)/#\1/g' \
  -e 's/^\(module gmsh\)$/\1\nusing gmsh_jll: libgmsh\nconst lib = libgmsh/g' \
  > ${prefix}/lib/gmsh.jl
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgmsh", "gmsh"], :libgmsh),
    FileProduct("lib/gmsh.jl",:gmsh_api)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,  preferred_gcc_version=v"7")
