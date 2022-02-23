# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gmsh"
version = v"4.9.3"

# Collection of sources required to build Gmsh
sources = [
    ArchiveSource("https://gmsh.info/src/gmsh-$(version)-source.tgz",
                  "9e06751e9fef59ba5ba8e6feded164d725d7e9bc63e1cb327b083cbc7a993adb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gmsh-*
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
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
