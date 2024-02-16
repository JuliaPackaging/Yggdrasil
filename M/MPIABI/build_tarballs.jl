using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MPIABI"
version = v"4.2.0"

sources = [
    GitSource("https://github.com/mpiwg-abi/header_and_stub_library", "8d187fc938c59f54e0435718dc16e45812904c2c"),
    DirectorySource("bundled"),
]

script = raw"""
cd header_and_stub_library

# Build regular C library
cmake -Bbuild -DCMAKE_FIND_ROOT_PATH=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel ${nproc}
cmake --install build
if [[ "$target" == *-mingw* ]]; then
   mv ${prefix}/lib/lib*.dll ${libdir}
fi
install_license LICENSE

# Build additional Fortran library
cp ../files/* .
gfortran -g -fPIC -c mpifstubs.f90
gfortran -g -fPIC -shared -o libmpif_abi.${dlext} mpifstubs.o
gfortran -g -fcray-pointer -c mpi.f90
perl -pi -e 's+[@]includedir[@]+'${includedir}'+' mpifc mpifort
perl -pi -e 's+[@]libdir[@]+'${libdir}'+' mpifc mpifort
install -Dvm 644 mpif.h ${includedir}/mpif.h
install -Dvm 644 mpi.mod ${includedir}/mpi.mod
install -Dvm 644 libmpif_abi.${dlext} ${libdir}/libmpif_abi.${dlext}
install -Dvm 755 mpifc ${bindir}/mpifc
install -Dvm 755 mpifort ${bindir}/mpifort
if [[ "$target" == *-mingw* ]]; then
   gfortran -g -fPIC -shared -o libmpif_abi.${dlext} -Wl,--out-implib,libmpif_abi.${dlext}.a mpifstubs.o
   install -Dvm 644 libmpif_abi.${dlext}.a ${prefix}/lib/libmpif_abi.${dlext}.a
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# Add `mpi+mpiabi` platform tag
for p in platforms
    p["mpi"] = "MPIABI"
end

products = [
    LibraryProduct("libmpi_abi", :libmpi),
    LibraryProduct("libmpif_abi", :libmpif),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267");
               compat="0.1", top_level=true),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
