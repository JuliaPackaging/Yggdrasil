# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "qr_mumps"
version = v"3.0.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://buttari.perso.enseeiht.fr/qr_mumps/releases/qr_mumps-$version.tgz",
                  "9e881f0734de05a89bee7866cb158985096f8930ed3e1e169e1874b85ec28396")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd qr_mumps*
mkdir build
cd build
cmake .. -DARITH="d;s;c;z" -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$prefix -DQRM_ORDERING_AMD=ON -DQRM_ORDERING_METIS=ON -DQRM_ORDERING_SCOTCH=ON -DQRM_WITH_STARPU=OFF -DQRM_WITH_CUDA=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_CROSSCOMPILING_EMULATOR=""
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())
filter!(p -> libgfortran_version(p) != v"3", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libqrm_common", :libqrm_common),
    LibraryProduct("libcqrm", :libcqrm),
    LibraryProduct("libsqrm", :libsqrm),
    LibraryProduct("libdqrm", :libdqrm),
    LibraryProduct("libzqrm", :libzqrm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"))
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0")
