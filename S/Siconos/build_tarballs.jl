# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Siconos"
version = v"4.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/siconos/siconos.git", "5b5a685c4f616aa514b0da1d0bd96009b1ad896f")
    DirectorySource("./bundled/")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd siconos/
mkdir build
cd build/
python3 -m pip install wheel packaging
cmake \
    -DUSER_OPTIONS_FILE=../../only_numerics.cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/siconos/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)      # Windows is not supported
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl"), platforms)        # Musl not supported
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libsiconos_numerics", :libsiconos_numerics)
    LibraryProduct("libsiconos_externals", :libsiconos_externals)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency(PackageSpec(name="CXSparse_jll", uuid="c77e7b6a-7cf9-58ed-a396-e1da12b05d87"))
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9.0.0")