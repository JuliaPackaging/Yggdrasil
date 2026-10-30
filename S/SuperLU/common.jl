# Shared by SuperLU_DIST@9 and SuperLU_DIST_CUDA@9. CI only rebuilds a recipe when a file in
# its own directory changes, so a change here also needs a `# Build trigger` bump in both.

const superlu_dist_version = v"9.3.1"

const superlu_dist_sources = [
    GitSource("https://github.com/xiaoyeli/superlu_dist.git", "9f7c8196d8f692cbfc59d81b61a74ceb4b37789b";
              tag="v$(superlu_dist_version)"),
    DirectorySource("../bundled"),
]

# `setup` runs in the source directory and can add to `EXTRA_CMAKE_ARGS`.
superlu_dist_script(setup::AbstractString) = raw"""
cd $WORKSPACE/srcdir/superlu_dist*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/output-name.patch

EXTRA_CMAKE_ARGS=()
""" * setup * raw"""

# Pick libblastrampoline.so / libblastrampoline-5.dll / libblastrampoline.dylib
# without an explicit Windows check.
BLAS_LIB=$(ls "${libdir}"/libblastrampoline*."${dlext}" | head -1)

build_superlu_dist()
{
    if [[ "${1}" == "Int64" ]]; then
        INT=64
        # METIS_jll installs this variant under its own prefix, so the DLL is in bin/ on Windows.
        METIS_PATH="${libdir}/metis/metis_Int64_Real32/$(basename ${libdir})/libmetis_Int64_Real32.${dlext}"
        PARMETIS_PATH="${libdir}/libparmetis_Int64_Real32.${dlext}"
    else
        INT=32
        METIS_PATH="${libdir}/libmetis.${dlext}"
        PARMETIS_PATH="${libdir}/libparmetis.${dlext}"
    fi

    cmake -B build-${INT} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_STATIC_LIBS=OFF \
        -DTPL_ENABLE_INTERNAL_BLASLIB=OFF \
        -Denable_tests=ON \
        -Denable_doc=OFF \
        -Denable_single=ON \
        -Denable_double=ON \
        -Denable_complex16=ON \
        -DTPL_BLAS_LIBRARIES="${BLAS_LIB}" \
        -DTPL_ENABLE_LAPACKLIB=ON \
        -DTPL_LAPACK_LIBRARIES="${BLAS_LIB}" \
        -DTPL_ENABLE_PARMETISLIB=ON \
        -DTPL_PARMETIS_INCLUDE_DIRS="${includedir}" \
        -DTPL_PARMETIS_LIBRARIES="${PARMETIS_PATH};${METIS_PATH}" \
        -DCMAKE_C_FLAGS="-std=c99 -Wno-implicit-function-declaration -Wno-incompatible-pointer-types" \
        -DXSDK_INDEX_SIZE=${INT} \
        -DXSDK_ENABLE_Fortran=OFF \
        -DSUPERLU_OUTPUT_NAME="superlu_dist_Int${INT}" \
        -Denable_examples=OFF \
        -Denable_python=OFF \
        "${EXTRA_CMAKE_ARGS[@]}"
    cmake --build build-${INT} --parallel ${nproc}
    cmake --install build-${INT}

    install -Dvm 755 build-${INT}/TEST/pdtest${exeext} "${bindir}/pdtest_${INT}${exeext}"
    install -vm 644 EXAMPLE/g20.rua "${includedir}"

    # Both widths install into ${includedir}, so the second build overwrites
    # the first's superlu_dist_config.h (XSDK_INDEX_SIZE). Keep a per-width
    # copy right after each install for consumers such as PETSc.
    mkdir -pv ${includedir}/superlu_dist_Int${INT}
    cp -v ${includedir}/superlu*.h* ${includedir}/superlu_dist_Int${INT}/
}
build_superlu_dist Int32
build_superlu_dist Int64
"""

const superlu_dist_products = [
    ExecutableProduct("pdtest_32", :pdtest_32),
    ExecutableProduct("pdtest_64", :pdtest_64),

    LibraryProduct("libsuperlu_dist_Int32", :libsuperlu_dist_Int32),
    LibraryProduct("libsuperlu_dist_Int64", :libsuperlu_dist_Int64),
]

const superlu_dist_dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.4.0"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"); compat="0.3.32"),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa"); compat="4.0.9"),
    Dependency("METIS_jll"; compat="5.1.4"),
]
