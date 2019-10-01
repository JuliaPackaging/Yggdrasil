using BinaryBuilder

# Collection of sources required to build Arpack
name = "Arpack"
version = v"3.7.0"
sources = [
    "https://github.com/opencollab/arpack-ng/archive/$(version).tar.gz" =>
    "972e3fc3cd0b9d6b5a737c9bf6fd07515c0d6549319d4ffb06970e64fa3cc2d6",
]

# Bash recipe for building across all platforms
script = raw"""
mkdir ${WORKSPACE}/srcdir/arpack-build

# arpack tests require finding libgfortran when linking with C linkers,
# and gcc doesn't automatically add that search path.  So we do it for it.
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

FFLAGS="${FFLAGS} -O2 -fPIC -ffixed-line-length-none -cpp"
LIBOPENBLAS=openblas
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    LIBOPENBLAS=openblas64_
    FFLAGS="${FFLAGS} -fdefault-integer-8 ${SYMBOL_DEFS[@]}"
fi

cd ${WORKSPACE}/srcdir/arpack-build
export LDFLAGS="${EXE_LINK_FLAGS[@]} -L$prefix/lib -lpthread"
cmake ../arpack-ng-* -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DBUILD_SHARED_LIBS=ON \
    -DBLAS_LIBRARIES="-l${LIBOPENBLAS}" \
    -DLAPACK_LIBRARIES="-l${LIBOPENBLAS}" \
    -DCMAKE_Fortran_FLAGS="${FFLAGS}"

make -j${nproc} VERBOSE=1
make install VERBOSE=1
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
    "OpenBLAS_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")

