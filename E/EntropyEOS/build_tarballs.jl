using BinaryBuilder, Pkg

name = "EntropyEOS"
version = v"1.3.0"

sources = [
    GitSource("https://github.com/eschnett/EntropyEOS.git", "db2189cfa5b0e685ddc195efe21a810305091154"; tag="v$(version)"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/EntropyEOS
# We use `-ffp-contract=off` to forbid re-arranging floating-point
# expressions. This way we can get bitwise identical results here in
# C++ and in a Julia code that implements the same algorithm.
make_options=(
    CXXFLAGS="-O2 -std=c++17 -ffp-contract=off"
    OPENMP=-fopenmp
    HDF5_INC="-I${includedir}"
    HDF5_LIB="-L${libdir} -lhdf5"
    PREFIX=${prefix}
)
make -j${nproc} "${make_options[@]}" lib tools
make "${make_options[@]}" install
for tool in eos_crop eos_repair eos_test; do
    install -Dvm 755 tools/${tool}${exeext} ${bindir}/${tool}${exeext}
done
install_license LICENSE.md
"""

# EntropyEOS does not use MPI, so it is built once per platform instead of once per
# MPI variant of HDF5_jll.
platforms = expand_cxxstring_abis(supported_platforms())

products = [
    ExecutableProduct("eos_crop", :eos_crop),
    ExecutableProduct("eos_repair", :eos_repair),
    ExecutableProduct("eos_test", :eos_test),
]

# HDF5_jll's headers include `mpi.h`, and linking against `libhdf5` needs the MPI library
# it was built with, which an MPI implementation provides at build time. OpenMPI 5 is
# not available on 32-bit platforms, so we use OpenMPI 4.
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("HDF5_jll"; compat="2.2.3"),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
    BuildDependency(PackageSpec(; name="OpenMPI_jll", version="4.1.11"); platforms=filter(!Sys.iswindows, platforms)),
    BuildDependency("MicrosoftMPI_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# HDF5_jll needs libgfortran5, i.e. GCC 8
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"8")
