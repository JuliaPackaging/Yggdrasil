# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenLSTO"
version = v"1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/M2DOLab/OpenLSTO.git", "853b9cc433b84c60cd1318a36f9a1d0e6cf65877"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
# New makefiles added, the patches fix some weird include issues mostly.
# There is likely a better way to fix them, or upstream the fixes.
script = raw"""
cp makefile_FEA $WORKSPACE/srcdir/OpenLSTO/M2DO_FEA/makefile
cp makefile_LSM $WORKSPACE/srcdir/OpenLSTO/M2DO_LSM/makefile
cp makefile_3D_LSM $WORKSPACE/srcdir/OpenLSTO/M2DO_3D_LSM/makefile
# At the moment we need GCC to build with OpenMP
export CXX=g++
cd $WORKSPACE/srcdir/OpenLSTO
atomic_patch -p1 ../patches/include_and_eigenpath.patch
cd $WORKSPACE/srcdir/OpenLSTO/M2DO_FEA
make -j${nproc}
make install
cd ../M2DO_LSM
mkdir bin
make -j${nproc}
make install
cd ../M2DO_3D_LSM
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/OpenLSTO/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true); skip=p->false)

# The products that we will ensure are always built
products = [
    LibraryProduct("m2do_fea", :m2do_fea),
    LibraryProduct("m2do_lsm", :m2do_lsm),
    LibraryProduct("m2do_3d_lsm", :m2do_3d_lsm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Eigen_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.6")
