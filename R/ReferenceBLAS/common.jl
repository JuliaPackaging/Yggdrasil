using BinaryBuilder, Pkg

version = v"3.12.1"

sources = [
    GitSource("https://github.com/Reference-LAPACK/lapack",
              "6ec7f2bc4ecf4c4a93496aa2fa519575bc0e39ca"),
]

# Bash recipe for building across all platforms

function blas_script(;blas32::Bool=false)
    script = """
    BLAS32=$(blas32)
    """

    script *= raw"""
    cd $WORKSPACE/srcdir/lapack*

    if [[ ${nbits} == 64 ]] && [[ "${BLAS32}" != "true" ]]; then
      INDEX64="ON"
    else
      INDEX64="OFF"
    fi

    # FortranCInterface_VERIFY fails on macOS, but it's not actually needed for the current build
    sed -i 's/FortranCInterface_VERIFY/# FortranCInterface_VERIFY/g' ./CBLAS/CMakeLists.txt
    sed -i 's/FortranCInterface_VERIFY/# FortranCInterface_VERIFY/g' ./LAPACKE/include/CMakeLists.txt

    # Use -fno-optimize-sibling-calls to guard against issues with Fortran ABI with character arguments
    # Discussed in https://github.com/JuliaLang/LinearAlgebra.jl/issues/650
    mkdir build && cd build
    cmake .. \
       -DCMAKE_INSTALL_PREFIX="$prefix" \
       -DCMAKE_FIND_ROOT_PATH="$prefix" \
       -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
       -DCMAKE_Fortran_FLAGS="-fno-optimize-sibling-calls" \
       -DCMAKE_BUILD_TYPE=Release \
       -DBUILD_SHARED_LIBS=ON \
       -DTEST_FORTRAN_COMPILER=OFF \
       -DBUILD_INDEX64_EXT_API=${INDEX64}

    make -j${nproc}
    make install
    if [[ ${target} == *mingw* ]]; then
      rm ${prefix}/lib/liblapack.dll.a
    fi
    rm ${libdir}/liblapack.*
    install_license $WORKSPACE/srcdir/lapack/LICENSE

    if [[ "${BLAS32}" == "true" ]]; then
        mv -v ${libdir}/libblas.${dlext} ${libdir}/libblas32.${dlext}
        # If there were links that are now broken, fix them up
        for l in $(find ${prefix}/lib -xtype l); do
          if [[ $(basename $(readlink ${l})) == libblas ]]; then
            ln -vsf libblas32.${dlext} ${l}
          fi
        done
        PATCHELF_FLAGS=()
        # ppc64le and aarch64 have 64 kB page sizes, don't muck up the ELF section load alignment
        if [[ ${target} == aarch64-* || ${target} == powerpc64le-* ]]; then
          PATCHELF_FLAGS+=(--page-size 65536)
        fi
        if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
          patchelf ${PATCHELF_FLAGS[@]} --set-soname libblas32.${dlext} ${libdir}/libblas32.${dlext}
        elif [[ ${target} == *apple* ]]; then
          install_name_tool -id libblas32.${dlext} ${libdir}/libblas32.${dlext}
        fi
    fi
    """
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]
