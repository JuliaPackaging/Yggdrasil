using BinaryBuilder

name = "SLATE"
version = v"1.0.0"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    GitSource("https://bitbucket.org/icl/slate.git", "859efbd6ad7dfc3efc190701676d2e0a0d8987fb")
]

# Bash recipe for building across all platforms
script = raw"""
cd slate
git submodule update --init
mkdir build && cd build
cmake \
  -DCMAKE_INSTALL_PREFIX=${prefix} \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE="Release" \
  -Dblas=openblas \
  -Dc_api=yes \
  -Dbuild_tests=no \
  -DMPI_RUN_RESULT_CXX_libver_mpi_normal="0" \
  -DMPI_RUN_RESULT_CXX_libver_mpi_normal__TRYRUN_OUTPUT="" \
  -Drun_result="0" \
  -Drun_result__TRYRUN_OUTPUT="ok" \
  ..
make -j${nproc}
make install
"""

# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(expand_cxxstring_abis(supported_platforms(;experimental=true, exclude=Sys.iswindows)))
platforms = filter(p -> !(Sys.iswindows(p) || libc(p) == "musl"), platforms)
platforms = filter(!Sys.isfreebsd, platforms)
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> libgfortran_version(p) ≠ v"3", platforms)
products = Product[
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("MPItrampoline_jll", compat="2"),
    #Dependency("MicrosoftMPI_jll"),
    Dependency("SCALAPACK_jll")
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
