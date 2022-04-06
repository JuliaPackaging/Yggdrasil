# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "blis"
version = v"0.8.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flame/blis.git", "c9700f369aa84fc00f36c4b817ffb7dab72b865d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd blis/

for i in ./config/*/*.mk; do

    # Building in container forbids -march options <<< Settings overrided.
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
    *"x86_64"*"freebsd"*) 
        export BLI_CONFIG=x86_64
        export BLI_THREAD=openmp
        ;;
    *"aarch64"*"apple"*)
        # Metaconfig arm64 is not needed here.
        # All Mac processors should have equal or higher specs then firestorm
        export BLI_CONFIG=firestorm
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
    *)
        # Default (Generic) configuration without optimized kernel.
        export BLI_CONFIG=generic
        export BLI_THREAD=none
        ;; 

esac

# For 64-bit builds, add _64 suffix to exported BLAS routines.
# This corresponds to ILP64 handling of OpenBLAS thus Julia.
if [ ${nbits} = 64 ]; then
    patch frame/include/bli_macro_defs.h < ${WORKSPACE}/srcdir/patches/bli_macro_defs.h.f77suffix64.patch
fi

# Include SVE support in this metaconfig.
if [ ${BLI_CONFIG} = arm64 ]; then
    # Add SVE configs to the registry.
    patch config_registry < ${WORKSPACE}/srcdir/patches/config_registry.metaconfig+armsve.patch

    # Unscreen Arm SVE code for metaconfig.
    patch kernels/armsve/bli_kernels_armsve.h \
        < ${WORKSPACE}/srcdir/patches/armsve_kernels_unscreen_arm_sve_h.patch
    patch kernels/armsve/1m/old/bli_dpackm_armsve512_int_12xk.c \
        < ${WORKSPACE}/srcdir/patches/armsve_kernels_unscreen_arm_sve_h.patch
    patch kernels/armsve/1m/bli_dpackm_armsve256_int_8xk.c \
        < ${WORKSPACE}/srcdir/patches/armsve_kernels_unscreen_arm_sve_h.patch

    # Config armsve depends on some family header defines.
    cp config/armsve/bli_family_armsve.h config/arm64/bli_family_arm64.h

    # Screen out SVE instructions in config-stage.
    patch config/a64fx/bli_cntx_init_a64fx.c \
        < ${WORKSPACE}/srcdir/patches/a64fx_config_screen_sector_cache.patch
    patch config/armsve/bli_cntx_init_armsve.c \
        < ${WORKSPACE}/srcdir/patches/armsve_config_screen_non_sve.patch
fi

export BLI_F77BITS=${nbits}
./configure -p ${prefix} -t ${BLI_THREAD} -b ${BLI_F77BITS} ${BLI_CONFIG}
make -j${nproc}
make install

# Static library is not needed.
rm ${prefix}/lib/libblis.a

# Rename .dll for Windows targets.
if [[ "${target}" == *"x86_64"*"w64"* ]]; then
    mkdir -p ${libdir}
    mv ${prefix}/lib/libblis.4.dll ${libdir}/libblis.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "freebsd")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libblis", :blis)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"11", lock_microarchitecture=false, julia_compat="1.6")
