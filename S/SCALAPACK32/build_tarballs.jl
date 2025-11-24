using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SCALAPACK32"
version = v"2.2.2"

sources = [
  GitSource("https://github.com/Reference-ScaLAPACK/scalapack", "25935e1a7e022ede9fd71bd86dcbaa7a3f1846b7"),
  DirectorySource("bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack

# use Make instead of CMake to compile SCALAPACK on Windows platforms
# CMake is unable to detect Microsoft-MPI
cp ${WORKSPACE}/srcdir/files/SLmake.inc SLmake.inc

if [[ "${target}" == *mingw* ]]; then
    make lib
    $FC -shared $(flagon -Wl,--whole-archive) libscalapack32.a $(flagon -Wl,--no-whole-archive) -lblastrampoline-5 -L$libdir -lmsmpi -o ${libdir}/libscalapack32.${dlext}
else
    CPPFLAGS=()
    CFLAGS=(-Wno-error=implicit-function-declaration)
    FFLAGS=(-ffixed-line-length-none)

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

    LBT=(-lblastrampoline)
    MPILIBS=()
    if [[ ${bb_full_target} == *mpich* ]]; then
        MPILIBS=(-lmpifort -lmpi)
    elif [[ ${bb_full_target} == *mpitrampoline* ]]; then
        MPILIBS=(-lmpitrampoline)
    elif [[ ${bb_full_target} == *openmpi* ]]; then
        MPILIBS=(-lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi)
    fi

    CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix}
                 -DCMAKE_FIND_ROOT_PATH=${prefix}
                 -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
                 -DCMAKE_Fortran_FLAGS="${CPPFLAGS[*]} ${FFLAGS[*]}"
                 -DCMAKE_C_FLAGS="${CPPFLAGS[*]} ${CFLAGS[*]}"
                 -DCMAKE_BUILD_TYPE=Release
                 -DBLAS_LIBRARIES="${LBT[*]} ${MPILIBS[*]}"
                 -DLAPACK_LIBRARIES="${LBT[*]}"
                 -DSCALAPACK_BUILD_TESTS=OFF
                 -DBUILD_SHARED_LIBS=ON
                 -DMPI_BASE_DIR="${prefix}"
                 -DCDEFS=Add_)

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
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_gfortran_versions(supported_platforms())

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack32", :libscalapack32),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
# We need at least GCC 5 for MPICH
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.9", preferred_gcc_version=v"5")
