# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "deal_II"
version = v"9.7.1"

# collection of sources required to complete build
sources = [
  ArchiveSource("https://dealii.org/downloads/dealii-$(version).tar.gz",
                "0f2096ef83db54fdcebe9f3d148fa713f63f1c3f567941b53bcb4a1a8ea7de43")
  DirectorySource("./bundled/")
]

# bash recipe for building across all platforms
script = raw"""
# make our own, more modern cmake visible
apk del cmake

# build writes to /tmp, which is a small tmpfs in our sandbox
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

cmake_options=(
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DDEAL_II_COMPONENT_DOCUMENTATION=OFF \
  -DDEAL_II_COMPONENT_EXAMPLES=OFF \
  -DDEAL_II_WITH_ADOLC=OFF \
  -DDEAL_II_WITH_ARBORX=OFF \
  -DDEAL_II_WITH_ARPACK=OFF \
  -DDEAL_II_WITH_ASSIMP=OFF \
  -DDEAL_II_WITH_BOOST=ON \
  -DDEAL_II_WITH_CGAL=OFF \
  -DDEAL_II_WITH_COMPLEX_VALUES=OFF \
  -DDEAL_II_WITH_GINKGO=OFF \
  -DDEAL_II_WITH_GMSH=OFF \
  -DDEAL_II_WITH_GSL=ON \
  -DDEAL_II_WITH_HDF5=OFF \
  -DDEAL_II_WITH_KOKKOS=ON \
  -DDEAL_II_WITH_LAPACK=ON \
  -DDEAL_II_WITH_MAGIC_ENUM=OFF \
  -DDEAL_II_WITH_METIS=OFF \
  -DDEAL_II_WITH_MPI=ON \
  -DDEAL_II_WITH_MUMPS=OFF \
  -DDEAL_II_WITH_MUPARSER=ON \
  -DDEAL_II_WITH_OPENCASCADE=OFF \
  -DDEAL_II_WITH_P4EST=ON \
  -DDEAL_II_WITH_PETSC=OFF \
  -DDEAL_II_WITH_PSBLAS=OFF \
  -DDEAL_II_WITH_SCALAPACK=OFF \
  -DDEAL_II_WITH_SLEPC=OFF \
  -DDEAL_II_WITH_SUNDIALS=OFF \
  -DDEAL_II_WITH_SYMENGINE=OFF \
  -DDEAL_II_WITH_TASKFLOW=ON \
  -DDEAL_II_WITH_TBB=OFF \
  -DDEAL_II_WITH_TRILINOS=OFF \
  -DDEAL_II_WITH_UMFPACK=ON \
  -DDEAL_II_WITH_VTK=OFF 
  -DDEAL_II_WITH_ZLIB=ON \
)

if [[ ${bb_full_target} == *mpiabi* ]]; then
  # MPIABI splits the C and Fortran MPI bindings
  cmake_options+=(
    -DMPI_C_COMPILER=mpicc
    -DMPI_Fortran_COMPILER=mpifc
  )
else
  cmake_options+=(
    -DMPI_HOME=${prefix}
  )
fi

# needed to support compiling for older macOS systems
if [[ "${target}" == *x86_64-apple* ]]; then
  export CPPFLAGS="-D_LIBCPP_DISABLE_AVAILABILITY"
fi

mkdir bin
# expand_instantiations is called during the build, compile for the host arch
$CXX_BUILD dealii-*/cmake/scripts/expand_instantiations.cc -o bin/expand_instantiations
export PATH="$PWD/bin:$PATH"

export CPPFLAGS="${CPPFLAGS} -I${includedir} -std=c++17"
export LDFLAGS="-L${libdir}"

export MPITRAMPOLINE_CC="${CC}"
export MPITRAMPOLINE_CXX="${CXX}"
export MPITRAMPOLINE_FC="${FC}"

# apply patches
cd $WORKSPACE/srcdir/dealii-*

# fixes issue in triangulation class causing problems in another (tbr) package
# (until deal.II v9.8 is published)
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/triangulation.patch"
cd ..

# build deal.II
mkdir build
cd build
cmake "${cmake_options[@]}"  ../dealii-*/
make -j${nproc}

# the licence of the package is expected to be in this directory
mkdir -p ${prefix}/share/licenses/deal_II/bundled
BUNDLED=(kokkos-4.5.01 taskflow-3.10.0)
cp $WORKSPACE/srcdir/dealii-*/LICENSE.md ${prefix}/share/licenses/deal_II/LICENSE
for item in "${BUNDLED[@]}"; do
  mkdir ${prefix}/share/licenses/deal_II/bundled/$item
  cp $WORKSPACE/srcdir/dealii-*/bundled/${item}/LICENSE ${prefix}/share/licenses/deal_II/bundled/${item}/LICENSE
done
mkdir ${prefix}/share/licenses/deal_II/bundled/umfpack
cp $WORKSPACE/srcdir/dealii-*/bundled/umfpack/lgpl-2.1.txt ${prefix}/share/licenses/deal_II/bundled/umfpack/LICENSE

make install
"""

augment_platform_block = """
  using Base.BinaryPlatforms
  $(MPI.augment)
  augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# these are the platforms we will build for by default, unless further platforms
# are passed in on the command line
platforms = supported_platforms()

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# due to P4est
platforms = filter(p -> !(Sys.iswindows(p) && nbits(p) == 32), platforms)
platforms = filter(p -> !(p["mpi"] in ["openmpi", "mpiabi"]), platforms)

# due to Kokkos
platforms = filter(p -> nbits(p) == 64, platforms)

# due to HDF5
sources, script = require_macos_sdk("14.0", sources, script)

# due to GSL
platforms = filter(p -> p["arch"] != "riscv64", platforms)
platforms = filter(p -> p["os"] != "freebsd", platforms)

# Windows builds with MinGW are not supported by deal.II
# see https://github.com/dealii/dealii/wiki/Windows#cygwin--minggw
platforms = filter(p -> !Sys.iswindows(p), platforms)

# powerpc64le builds fail due to missing support for long doubles in Boost
# furthermore: https://github.com/dealii/dealii/wiki/Power-architecture
platforms = filter(p -> p["arch"] != "powerpc64le", platforms)

# the products that we will ensure are always built
products = [
  LibraryProduct("libdeal_II", :libdeal_II),
]

# dependencies that must be installed before this package can be built
# commented dependencies might be added in the future but stay here for reference
dependencies = [
  HostBuildDependency("CMake_jll"),
  RuntimeDependency(PackageSpec(name="MPIPreferences",
                                uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267")),
#  Dependency(PackageSpec(name="OCCT_jll",
#                         uuid="baad4e97-8daa-5946-aac2-2edac59d34e1")),
  Dependency(PackageSpec(name="GSL_jll",
                         uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"),
             compat="~2.7.2"),
  Dependency(PackageSpec(name="HDF5_jll",
                         uuid="0234f1f7-429e-5d53-9886-15a909be8d59")),
#  Dependency(PackageSpec(name="gmsh_jll",
#                         uuid="630162c2-fc9b-58b3-9910-8442a8a132e6")),
  Dependency(PackageSpec(name="muparser_jll",
                         uuid="888e69b1-873b-5047-a2fc-24c07cbe9dc8")),
  Dependency(PackageSpec(name="OpenBLAS32_jll",
                         uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
  Dependency(PackageSpec(name="P4est_jll",
                         uuid="6b5a15aa-cf52-5330-8376-5e5d90283449")),
  Dependency(PackageSpec(name="Zlib_jll",
                         uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
]
append!(dependencies, platform_dependencies)

# don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the
# shared libraries. (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_tarballs(ARGS, name, version, sources, script, platforms, products,
               dependencies; augment_platform_block, julia_compat="1.10",
               preferred_gcc_version = v"9.1.0")
