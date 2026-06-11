using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HYPRE64"
version = v"3.1.0"
offset = 0
ygg_version = VersionNumber(version.major, version.minor, 100 * version.patch + offset)

sources = [
    GitSource("https://github.com/hypre-space/hypre.git", "9dc9e18aed6a945a95f966e57daacfb1c269f6ec") # Tag v3.1.0
]

script = raw"""
cd $WORKSPACE/srcdir/hypre/src

sed -i '$i\
\
/* HYPRE64 override: rename external BLAS\/LAPACK calls to _64_-suffixed names\
   so they resolve to libblastrampoline'\''s ILP64 slot. */\
#undef hypre_F90_NAME_BLAS\
#undef hypre_F90_NAME_LAPACK\
#define hypre_F90_NAME_BLAS(name,NAME)   name##_64_\
#define hypre_F90_NAME_LAPACK(name,NAME) name##_64_\
' utilities/_hypre_fortran.h

if [[ "${target}" == *mingw* ]]; then
    LBT=(-lblastrampoline-5)
else
    LBT=(-lblastrampoline)
fi

MPI_SETTINGS=(-DMPI_HOME=${prefix})
if [[ "${target}" == x86_64-w64-mingw32 ]]; then
    MPI_SETTINGS+=(
        -DMPI_GUESS_LIBRARY_NAME=MSMPI
        -DMPI_C_LIBRARIES=msmpi64
        -DMPI_CXX_LIBRARIES=msmpi64
    )
fi

mkdir build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DHYPRE_ENABLE_BIGINT=ON \
    -DHYPRE_ENABLE_HYPRE_BLAS=OFF \
    -DHYPRE_ENABLE_HYPRE_LAPACK=OFF \
    -DTPL_BLAS_LIBRARIES="${LBT[*]}" \
    -DTPL_LAPACK_LIBRARIES="${LBT[*]}" \
    -DHYPRE_ENABLE_OPENMP=ON \
    -DHYPRE_ENABLE_CUDA_STREAMS=OFF \
    -DHYPRE_ENABLE_CUSPARSE=OFF \
    -DHYPRE_ENABLE_CURAND=OFF \
    "${MPI_SETTINGS[@]}"

make -j${nproc}
make install

cd ${libdir}
old_files=$(ls libHYPRE.* 2>/dev/null || true)
for f in $old_files; do
    new=${f/libHYPRE/libHYPRE64}
    if [ -L "$f" ]; then
        tgt=$(readlink "$f")
        rm -f "$f"
        ln -sf "${tgt/libHYPRE/libHYPRE64}" "$new"
    elif [ -f "$f" ]; then
        mv -v "$f" "$new"
    fi
done

# Move the headers into their own subdirectory: stock HYPRE_jll installs
# the same header names (notably HYPRE_config.h, which records the
# integer width) into ${includedir}, and the two packages must be
# co-installable for consumers that build against both integer widths
# (e.g. PETSc).
mkdir -p ${includedir}/HYPRE64
mv ${includedir}/HYPRE*.h ${includedir}/HYPRE64/

if [[ "${target}" == *apple* ]]; then
    install_name_tool -id "@rpath/libHYPRE64.${dlext}" ${libdir}/libHYPRE64.${dlext}
elif [[ "${target}" == *mingw* ]]; then
    :
else
    real_lib=$(find ${libdir} -maxdepth 1 -name 'libHYPRE64.so.*' -not -type l | head -1)
    if [ -n "$real_lib" ]; then
        soname=$(patchelf --print-soname "$real_lib")
        case "$soname" in
            libHYPRE64.*) ;;
            libHYPRE.*) patchelf --set-soname "${soname/libHYPRE/libHYPRE64}" "$real_lib" ;;
        esac
    fi
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    LibraryProduct("libHYPRE64", :libHYPRE)
]

dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.4.0"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms))
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version = v"8")
