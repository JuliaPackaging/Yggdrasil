# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Packmol"
version = v"20.3.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://leandro.iqm.unicamp.br/m3g/packmol/packmol.tar.gz", "21c249670e08dfed142658030ea58bc4473483a4b9da263abff13588f3c47f31")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd packmol/
mkdir -p $prefix/shared/licenses
cp LICENSE $prefix/shared/licenses
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("packmol", :packmol)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
