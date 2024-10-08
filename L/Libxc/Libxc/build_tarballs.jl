using BinaryBuilder, Pkg

name = "Libxc"
version = v"6.2.2"
include("../sources.jl")


# Bash recipe for building across all platforms
# Notes:
#   - 3rd and 4th derivatives (KXC, LXC) not built since gives a binary size of ~200MB
script = raw"""
cd $WORKSPACE/srcdir/libxc-*/

mkdir libxc_build
cd libxc_build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release -DENABLE_XHOST=OFF -DBUILD_SHARED_LIBS=ON \
    -DENABLE_FORTRAN=OFF -DDISABLE_KXC=ON ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="1.8")
