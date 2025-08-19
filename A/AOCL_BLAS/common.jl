# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

version = v"5.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/amd/blis.git", "16f852a065e76e824d77bc39e2baa82ac19ed419"),
    DirectorySource("../bundled")
]

# Bash recipe for building across all platforms
# Most of the script is adapted from blis
function blis_script(; blis32::Bool=false)
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

    # Only consider AMD Zen CPUs
    export BLI_CONFIG=amdzen
    export BLI_THREAD=openmp

    # For 64-bit builds, add _64 suffix to exported BLAS routines.
    # This corresponds to ILP64 handling of OpenBLAS thus Julia.
    if [[ ${nbits} == 64 ]] && [[ "${BLIS32}" != "true" ]]; then
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/suffix64.patch
    fi

    # Import libblastrampoline-style nthreads setter.
    cp ${WORKSPACE}/srcdir/nthreads64_.c frame/compat/nthreads64_.c

    if [[ "${BLIS32}" == "true" ]]; then
        export BLI_F77BITS=32
    else
        export BLI_F77BITS=${nbits}
    fi
    ./configure --enable-cblas -p ${prefix} -t ${BLI_THREAD} -b ${BLI_F77BITS} --enable-aocl-dynamic ${BLI_CONFIG}
    make -j${nproc}
    make install

    # Static library is not needed.
    rm ${prefix}/lib/libblis.a

    # Rename .dll for Windows targets.
    if [[ "${target}" == *"x86_64"*"w64"* ]]; then
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

        if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
            patchelf ${PATCHELF_FLAGS[@]} --set-soname libblis32.${dlext} ${libdir}/libblis32.${dlext}
        fi
    fi

    install_license LICENSE
    """
end

# Only platforms relevant to AMD Zen CPUs
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "freebsd")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]
