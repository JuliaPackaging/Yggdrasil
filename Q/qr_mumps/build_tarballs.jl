# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "qr_mumps"
version = v"3.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.com/qr_mumps/qr_mumps.git" ,"3ed9c3a42c7bb620c90c9c816097654c5d2cfc60")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qr_mumps*
mkdir build
cd build

if [[ "${target}" == *mingw* ]]; then
    LBT=libblastrampoline-5
else
    LBT=libblastrampoline
fi

cmake .. -DARITH="d;s;c;z" -DBUILD_SHARED_LIBS=ON \
                           -DCMAKE_INSTALL_PREFIX=$prefix \
                           -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
                           -DCMAKE_CROSSCOMPILING_EMULATOR="" \
                           -DQRM_WITH_TESTS=OFF \
                           -DQRM_WITH_EXAMPLES=OFF \
                           -DQRM_ORDERING_AMD=ON \
                           -DQRM_ORDERING_METIS=ON \
                           -DQRM_ORDERING_SCOTCH=ON \
                           -DQRM_WITH_STARPU=OFF \
                           -DQRM_WITH_CUDA=OFF \
                           -DBLAS_LIBRARIES="${libdir}/${LBT}.${dlext}" \
                           -DLAPACK_LIBRARIES="${libdir}/${LBT}.${dlext}" \
                           -DMETIS_LIBRARIES="${libdir}/libmetis.${dlext}" \
                           -DAMD_LIBRARIES="${libdir}/libamd.${dlext};${libdir}/libcolamd.${dlext}" \
                           -DCMAKE_BUILD_TYPE=Release

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
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c")),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"); compat="7.0.6")
    # Dependency(PackageSpec(name="StarPU_jll", uuid="e3ad0b27-b140-5312-a56e-059adfc55eb4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_gcc_version=v"9.1.0", clang_use_lld=false)
