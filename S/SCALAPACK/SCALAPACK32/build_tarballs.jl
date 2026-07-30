using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SCALAPACK32"
version = v"2.2.3"
# ygg_version.patch = 100 * version.patch + offset; bump `offset` for rebuilds.
offset = 0
ygg_version = VersionNumber(version.major, version.minor, 100 * version.patch + offset)

sources = [
  GitSource("https://github.com/Reference-ScaLAPACK/scalapack", "3e0da655fb07de5f1d76d6afb43f16ae17ca98c4"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack

apk del cmake

# v2.2.3 try_run()s a Fortran-mangling probe; fails under cross-compile.
cat > CMAKE/FortranMangling.cmake <<'EOF'
include_guard()
EOF

CFLAGS=(-Wno-error=implicit-function-declaration)
FFLAGS=(-cpp -ffixed-line-length-none)

# Add `-fallow-argument-mismatch` if supported
: >empty.f
if gfortran -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    FFLAGS+=(-fallow-argument-mismatch)
fi
rm -f empty.*

# Add `-fcray-pointer` if supported
: >empty.f
if gfortran -c -fcray-pointer empty.f >/dev/null 2>&1; then
    FFLAGS+=(-fcray-pointer)
fi
rm -f empty.*

if [[ "${target}" == *mingw* ]]; then
  LBT=(-lblastrampoline-5)
else
  LBT=(-lblastrampoline)
fi

# We need to specify the MPI libraries explicitly because the
# CMakeLists.txt doesn't properly add them when linking
MPI_SETTINGS=(-DMPI_BASE_DIR="${prefix}")
MPILIBS=()
if [[ ${bb_full_target} == *microsoftmpi* ]]; then
    MPI_SETTINGS+=(-DMPI_GUESS_LIBRARY_NAME=MSMPI)
    MPILIBS=(-lmsmpifec64 -lmsmpi64)
elif [[ ${bb_full_target} == *mpiabi* ]]; then
    MPILIBS=(-lmpif -lmpi_abi)
elif [[ ${bb_full_target} == *mpich* ]]; then
    MPILIBS=(-lmpifort -lmpi)
elif [[ ${bb_full_target} == *mpitrampoline* ]]; then
    MPILIBS=(-lmpitrampoline)
elif [[ ${bb_full_target} == *openmpi* ]]; then
    MPILIBS=(-lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi)
fi

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix}
             -DCMAKE_FIND_ROOT_PATH=${prefix}
             -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
             -DCMAKE_Fortran_FLAGS="${FFLAGS[*]}"
             -DCMAKE_C_FLAGS="${CFLAGS[*]}"
             -DCMAKE_BUILD_TYPE=Release
             -DBLAS_LIBRARIES="${LBT[*]} ${MPILIBS[*]}"
             -DLAPACK_LIBRARIES="${LBT[*]}"
             -DSCALAPACK_BUILD_TESTS=OFF
             -DBUILD_SHARED_LIBS=ON
             ${MPI_SETTINGS[*]}
             -DCDEFS=Add_)

mkdir build
cd build
cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc} all
make install

mv -v ${libdir}/libscalapack.${dlext} ${libdir}/libscalapack32.${dlext}

for l in $(find ${prefix}/lib -xtype l); do
  if [[ $(basename $(readlink ${l})) == libscalapack ]]; then
    ln -vsf libscalapack32.${dlext} ${l}
  fi
done

PATCHELF_FLAGS=()
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

platforms = expand_gfortran_versions(supported_platforms())
# Don't know how to configure MPI for Windows
platforms = filter(p -> !Sys.iswindows(p), platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack32", :libscalapack32),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency("mpif_jll"; compat="0.1.5", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)), # MPI Fortran bindings
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"9")
