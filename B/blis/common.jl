# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flame/blis.git",
              "e8566eb3e773fb54d11b33e371d13f22d2941e50"),
    DirectorySource("../bundled")
]

# Bash recipe for building across all platforms
function blis_script(;blis32::Bool=false)
    script = """
    BLIS32=$(blis32)
    """

    script *= raw"""
    cd $WORKSPACE/srcdir/blis

    for i in ./config/*/*.mk; do

        # Building in container forbids -march options <<< Settings overriden.
        # sed -i "s/-march[^ ]*//g" $i

        # Building in container forbids unsafe optimization.
        sed -i "s/-ffast-math//g" $i
        sed -i "s/-funsafe-math-optimizations//g" $i

    done

    case ${target} in

        *"x86_64"*"linux"*)
            export BLI_CONFIG=x86_64
            export BLI_THREAD=openmp
            ;;
        *"aarch64"*"linux"*)
            export BLI_CONFIG=arm64
            export BLI_THREAD=openmp
            ;;
        *"arm"*"linux"*)
            export BLI_CONFIG=arm32
            export BLI_THREAD=none
            ;;
        *"x86_64"*"w64"*)
            # MinGW doesn't support savexmm instructions
            # Build only for AMD processors.
            export BLI_CONFIG=amd64
            export BLI_THREAD=openmp
            ;;
        *"x86_64"*"apple"*)
            export BLI_CONFIG=x86_64
            export BLI_THREAD=openmp
            ;;
        *"aarch64"*"apple"*)
            export BLI_CONFIG=firestorm
            export BLI_THREAD=openmp
            ;;
        *"x86_64"*"freebsd"*)
            export BLI_CONFIG=x86_64
            export BLI_THREAD=openmp
            ;;
        *"aarch64"*"freebsd"*)
            export BLI_CONFIG=arm64
            export BLI_THREAD=openmp
            ;;
       *"powerpc64le"*)
            export BLI_CONFIG=power
            export BLI_THREAD=openmp
            ;;
       *)
            # Default (Generic) configuration without optimized kernel.
            # For now, RISC-V uses the generic kernels here until upstream implements a meta target: https://github.com/flame/blis/issues/902
            export BLI_CONFIG=generic
            export BLI_THREAD=none
            ;;

    esac

    # For 64-bit builds, add _64 suffix to exported BLAS routines.
    # This corresponds to ILP64 handling of OpenBLAS thus Julia.
    if [[ ${nbits} == 64 ]] && [[ "${BLIS32}" != "true" ]]; then
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/bli_macro_defs.h.f77suffix64.patch
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cblas_f77suffix64.patch
    fi

    # Replace cblas function names to have _64 suffixes
    if [[ "${BLIS32}" != "true" ]]; then
       cd frame/compat/cblas/src
       sed -i -E "s/cblas_([a-zA-Z0-9_]+)/cblas_\164_/g" cblas.h
       for fname in *.c extra/*.c; do
           sed -i -E "/^#/!s/cblas_([a-zA-Z0-9_]+)\(/cblas_\164_\(/g" $fname
       done
       for fname in extra/*.c; do
           sed -i -E "/^#s/cblas_([a-zA-Z0-9_]+)\"/cblas_\164_\"/g" $fname
           sed -i -E "/attribute/s/cblas_([a-zA-Z0-9_]+)/cblas_\164_/g" $fname
       done
       cd ../../../..
    fi   

    # Include A64FX in Arm64 metaconfig.
    if [ ${BLI_CONFIG} = arm64 ]; then
        # Add A64FX to the registry.
        patch config_registry ${WORKSPACE}/srcdir/patches/config_registry.metaconfig+a64fx.patch

        # Unscreen Arm SVE code for metaconfig.
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/armsve_kernels_unscreen_arm_sve_h.patch
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/armsve_kernels_unscreen_armsve512_int_12xk.patch
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/armsve_kernels_unscreen_armsve256_int_8x10.patch

        # Screen out A64FX sector cache.
        patch config/a64fx/bli_cntx_init_a64fx.c ${WORKSPACE}/srcdir/patches/a64fx_config_screen_sector_cache.patch
    fi

    # Import libblastrampoline-style nthreads setter.
    cp ${WORKSPACE}/srcdir/nthreads64_.c frame/compat/nthreads64_.c

    if [[ "${BLIS32}" == "true" ]]; then
        export BLI_F77BITS=32
    else
        export BLI_F77BITS=${nbits}
    fi

    ./configure --enable-cblas -p ${prefix} -t ${BLI_THREAD} -b ${BLI_F77BITS} ${BLI_CONFIG}
    make -j${nproc}
    make install

    # Static library is not needed.
    rm -f ${prefix}/lib/libblis.a

    # Rename .dll for Windows targets.
    if [[ "${target}" == *mingw* ]]; then
        mkdir -p ${libdir}
        mv ${prefix}/lib/libblis.4.dll ${libdir}/libblis.dll
    fi

    if [[ "${BLIS32}" == "true" ]]; then
        # Rename libblis.${dlext} into libblis32.${dlext}
        mv -v ${libdir}/libblis.${dlext} ${libdir}/libblis32.${dlext}

        # If there were links that are now broken, fix 'em up
        for l in $(find ${prefix}/lib -xtype l); do
          if [[ $(basename $(readlink ${l})) == libblis ]]; then
            ln -vsf libblis32.${dlext} ${l}
          fi
        done

        PATCHELF_FLAGS=()

        # ppc64le and aarch64 have 64 kB page sizes, don't muck up the ELF section load alignment
        if [[ ${target} == aarch64-* || ${target} == powerpc64le-* ]]; then
          PATCHELF_FLAGS+=(--page-size 65536)
        fi

        if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
          patchelf ${PATCHELF_FLAGS[@]} --set-soname libblis32.${dlext} ${libdir}/libblis32.${dlext}
        elif [[ ${target} == *apple* ]]; then
          install_name_tool -id libblis32.${dlext} ${libdir}/libblis32.${dlext}
        fi
    fi

    install_license LICENSE
    """
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]
