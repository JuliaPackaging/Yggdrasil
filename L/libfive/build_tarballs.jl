# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libfive"
version = v"0.1.0" # not yet tagged

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sjkelly/libfive.git", "ce9a35f8b22dafd260bdd521c7773b25026433e7")
]

dependencies = [
    Dependency("boost_jll"; compat="=1.76.0"),
    Dependency("Eigen_jll"),
    Dependency("libpng_jll")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libfive/

# Eigen Hack
ln -sf ${includedir}/eigen3/Eigen ${includedir}/Eigen

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_STUDIO_APP=OFF \
    -DBUILD_GUILE_BINDINGS=OFF \
    -DBUILD_PYTHON_BINDINGS=OFF \
    ..
make -j${nproc}
make install
install_license /usr/share/licenses/MPL2 #libfive is MPL2, studio is GPL3 (not distributed here)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)
platforms = expand_cxxstring_abis(platforms) #auditor requested

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libfive", :libfive),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7",lock_microarchitecture=false)