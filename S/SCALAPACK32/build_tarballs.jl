using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SCALAPACK32"
version = v"2.2.1"
scalapack_version = v"2.2.0"

sources = [
  ArchiveSource("https://github.com/Reference-ScaLAPACK/scalapack/archive/refs/tags/v$(scalapack_version).tar.gz",
                "8862fc9673acf5f87a474aaa71cd74ae27e9bbeee475dbd7292cec5b8bcbdcf3"),
  DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack-*

# the patch prevents running foreign executables, which fails on most platforms
# we instead set CDEFS manually below
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done

CPPFLAGS=()
CFLAGS=()
FFLAGS=(-cpp -ffixed-line-length-none)

# Add `-fallow-argument-mismatch` if supported
: >empty.f
if gfortran -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    FFLAGS+=(-fallow-argument-mismatch)
fi
rm -f empty.*

OPENBLAS=(-lopenblas)

MPILIBS=()
if grep -q MPICH "${prefix}/include/mpi.h"; then
    MPILIBS=(-lmpifort -lmpi)
elif grep -q MPItrampoline "${prefix}/include/mpi.h"; then
    MPILIBS=(-lmpitrampoline)
elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
    MPILIBS=(-lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi)
fi

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix}
             -DCMAKE_FIND_ROOT_PATH=${prefix}
             -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
             -DCMAKE_Fortran_FLAGS="${CPPFLAGS[*]} ${FFLAGS[*]}"
             -DCMAKE_C_FLAGS="${CPPFLAGS[*]} ${CFLAGS[*]}"
             -DCMAKE_BUILD_TYPE=Release
             -DBLAS_LIBRARIES="${OPENBLAS[*]} ${MPILIBS[*]}"
             -DLAPACK_LIBRARIES="${OPENBLAS[*]}"
             -DSCALAPACK_BUILD_TESTS=OFF
             -DBUILD_SHARED_LIBS=ON
             -DMPI_BASE_DIR="${prefix}")

export CDEFS="Add_"

mkdir build
cd build
cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc} all
make install

mv -v ${libdir}/libscalapack.${dlext} ${libdir}/libscalapack32.${dlext}

# If there were links that are now broken, fix 'em up
for l in $(find ${prefix}/lib -xtype l); do
  if [[ $(basename $(readlink ${l})) == libscalapack ]]; then
    ln -vsf libscalapack32.${dlext} ${l}
  fi
done

PATCHELF_FLAGS=()

# ppc64le and aarch64 have 64 kB page sizes, don't muck up the ELF section load alignment
if [[ ${target} == aarch64-* || ${target} == powerpc64le-* ]]; then
  PATCHELF_FLAGS+=(--page-size 65536)
fi

if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
  patchelf ${PATCHELF_FLAGS[@]} --set-soname libscalapack32.${dlext} ${libdir}/libscalapack32.${dlext}
elif [[ ${target} == *apple* ]]; then
  install_name_tool -id libscalapack32.${dlext} ${libdir}/libscalapack32.${dlext}
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_gfortran_versions(supported_platforms(; exclude=Sys.iswindows))

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# Internal compiler error for v2.2.0 for:
# - aarch64-linux-musl-libgfortran4-mpi+mpich
# - aarch64-linux-musl-libgfortran4-mpi+openmpi
platforms = filter(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libc(p) == "musl" && libgfortran_version(p) == v"4" && p["mpi"] == "mpich"), platforms)
platforms = filter(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libc(p) == "musl" && libgfortran_version(p) == v"4" && p["mpi"] == "openmpi"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack32", :libscalapack32),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
