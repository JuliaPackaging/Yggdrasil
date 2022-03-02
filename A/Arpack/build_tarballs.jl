using BinaryBuilder

# Collection of sources required to build Arpack
name = "Arpack"
version = v"3.5.1" # <-- This is actually v3.5.0, but we need to build for new platforms

sources = [
    GitSource("https://github.com/opencollab/arpack-ng.git",
              "9233f7f86f063ca6ca3793cb54dec590eb146e10"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/arpack-ng*

# arpack tests require finding libgfortran when linking with C linkers,
# and gcc doesn't automatically add that search path.  So we do it for it with `rpath-link`.
EXE_LINK_FLAGS=()
if [[ ${target} != *darwin* ]]; then
    EXE_LINK_FLAGS+=("-Wl,-rpath-link,/opt/${target}/${target}/lib")
    EXE_LINK_FLAGS+=("-Wl,-rpath-link,/opt/${target}/${target}/lib64")
fi

# Symbols that have float32, float64, complexf32, and complexf64 support
SDCZ_SYMBOLS=(
    axpy copy gemv geqr2 lacpy lahqr lanhs larnv lartg
    lascl laset scal trevc trmm trsen gbmv gbtrf gbtrs
    gttrf gttrs pttrf pttrs
)

# All symbols that have float32/float64 support (including the SDCZ_SYMBOLS above)
SD_SYMBOLS=(
    ${SDCZ_SYMBOLS[@]}
    dot ger labad laev2 lamch lanst lanv2
    lapy2 larf larfg lasr nrm2 orm2r rot steqr swap
)

# All symbols that have complexf32/complexf64 support (including the SDCZ_SYMBOLS above)
CZ_SYMBOLS=(${SDCZ_SYMBOLS[@]} dotc geru unm2r)

# Add in (s|d)*_64 symbol remappings:
SYMBOL_DEFS=()
for sym in ${SD_SYMBOLS[@]}; do
    SYMBOL_DEFS+=("-Ds${sym}=s${sym}_64" "-Dd${sym}=d${sym}_64")
done

# Add in (c|z)*_64 symbol remappings:
for sym in ${CZ_SYMBOLS[@]}; do
    SYMBOL_DEFS+=("-Dc${sym}=c${sym}_64" "-Dz${sym}=z${sym}_64")
done

# Add one-off symbol mappings; things that don't fit into any other bucket:
for sym in scnrm2 dznrm2 csscal zdscal dgetrf dgetrs; do
    SYMBOL_DEFS+=("-D${sym}=${sym}_64")
done

# Set up not only lowercase symbol remappings, but uppercase as well:
SYMBOL_DEFS+=(${SYMBOL_DEFS[@]^^})

FFLAGS="${FFLAGS} -O3 -fPIE -ffixed-line-length-none -fno-optimize-sibling-calls -cpp"
BLAS=blastrampoline
LAPACK=blastrampoline
if [[ ${nbits} == 64 ]]; then
    FFLAGS="${FFLAGS} -fdefault-integer-8 ${SYMBOL_DEFS[@]}"
fi

# Work around error
#
#     Error: Rank mismatch between actual argument at (1) and actual argument at (2) (scalar and rank-1)
#
# Properly fixed upstream in v3.8.0 with https://github.com/opencollab/arpack-ng/pull/245.
# TODO: Remove this line when we upgrade to that version.
if [[ "${target}" == aarch64-apple-* ]]; then
    FFLAGS="${FFLAGS} -fallow-argument-mismatch"
fi

mkdir build
cd build
export LDFLAGS="${EXE_LINK_FLAGS[@]} -L${libdir} -lpthread"
cmake .. -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DCMAKE_BUILD_TYPE=Release \
    -DEXAMPLES=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DBLAS_LIBRARIES="-l${BLAS}" \
    -DLAPACK_LIBRARIES="-l${LAPACK}" \
    -DCMAKE_Fortran_FLAGS="${FFLAGS}"

make -j${nproc} VERBOSE=1
make install VERBOSE=1

# For now, we'll have to adjust the name of the Lbt library on macOS and FreeBSD.
# Eventually, this should be fixed upstream
if [[ ${target} == *-apple-* ]] || [[ ${target} == *freebsd* ]]; then
    echo "-- Modifying library name for Lbt"

    for nm in libarpack; do
        # Figure out what version it probably latched on to:
        if [[ ${target} == *-apple-* ]]; then
            LBT_LINK=$(otool -L ${libdir}/${nm}.dylib | grep lib${BLAS} | awk '{ print $1 }')
            install_name_tool -change ${LBT_LINK} @rpath/lib${BLAS}.dylib ${libdir}/${nm}.dylib
        elif [[ ${target} == *freebsd* ]]; then
            LBT_LINK=$(readelf -d ${libdir}/${nm}.so | grep lib${BLAS} | sed -e 's/.*\[\(.*\)\].*/\1/')
            patchelf --replace-needed ${LBT_LINK} lib${BLAS}.so ${libdir}/${nm}.so
        elif [[ ${target} == *linux* ]]; then
            LBT_LINK=$(readelf -d ${libdir}/${nm}.so | grep lib${BLAS} | sed -e 's/.*\[\(.*\)\].*/\1/')
            patchelf --replace-needed ${LBT_LINK} lib${BLAS}.so ${libdir}/${nm}.so
        fi
    done
fi

# Delete the extra soversion libraries built. https://github.com/JuliaPackaging/Yggdrasil/issues/7
if [[ "${target}" == *-mingw* ]]; then
    rm -f ${libdir}/lib*.*.${dlext}
    rm -f ${libdir}/lib*.*.*.${dlext}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We enable the full
# combinatorial explosion of GCC versions because this package most
# definitely links against libgfortran.
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libarpack", :libarpack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.7")
