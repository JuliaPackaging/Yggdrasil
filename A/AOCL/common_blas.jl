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

    # Only consider AMD Zen CPUs
    export BLIS_CONFIG=amdzen
    export BLIS_THREAD=openmp

    for i in ./config/*/*.mk; do
        # Prevent any unsafe optimization
        sed -i "s/-ffast-math//g" $i
        sed -i "s/-funsafe-math-optimizations//g" $i
    done

    # Fix the unnecessary branching for Windows that caused errors/warnings
    if [[ "${target}" == *"x86_64"*"w64"* ]]; then
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/aocltpdef-mingw32.patch
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/blis_tls_type-mingw32.patch
    fi
    # Fix the format specifiers
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/aoclflist_format_specifier.patch

    if [[ "${BLIS32}" == "true" ]]; then
        export BLIS_F77BITS=32
    else
        export BLIS_F77BITS=${nbits}
    fi
    ./configure --enable-cblas --disable-static --enable-aocl-dynamic -p ${prefix} -t ${BLIS_THREAD} -b ${BLIS_F77BITS} ${BLIS_CONFIG}
    make -j${nproc}
    make install

    # Rename .dll for Windows targets
    if [[ "${target}" == *"x86_64"*"w64"* ]]; then
        mkdir -p ${libdir}
        mv ${prefix}/lib/libblis-mt.5.dll ${libdir}/libblis-mt-5.dll
    fi

    if [[ "${BLIS32}" == "true" ]]; then
        # Rename libblis-mt.${dlext} into libblis32-mt.${dlext}
        if [[ "${target}" == *"x86_64"*"w64"* ]]; then
            mv -v ${libdir}/libblis-mt-5.dll ${libdir}/libblis32-mt-5.dll
        else
            mv -v ${libdir}/libblis-mt.${dlext} ${libdir}/libblis32-mt.${dlext}
        fi
        # If there were links that are now broken, fix them
        for l in $(find ${prefix}/lib -xtype l); do
            if [[ $(basename $(readlink ${l})) == libblis ]]; then
                ln -vsf libblis32-mt.${dlext} ${l}
            fi
        done
    fi

    install_license LICENSE
    """
end

# Only platforms relevant to AMD Zen CPUs
platforms = supported_platforms(; exclude=p -> !(arch(p) == "x86_64" && !Sys.isapple(p)))

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]
