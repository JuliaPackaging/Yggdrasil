# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
name = "qpOASES"
version = v"3.2.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/qpOASES.git",
    "680f18c8ef0018a120e1604b769f056e8368df97"),
    DirectorySource("./bundled")
]

include("../../L/libjulia/common.jl")


# Bash recipe for building across all platforms
script = raw"""
apk del cmake
cd $WORKSPACE/srcdir
cd qpOASES

atomic_patch -p1  ${WORKSPACE}/srcdir/patches/mypatch.patch

rm Makefile
rm *.mk
mkdir build && cd build
if [[ "$nbits" == "64" ]]; then
    LOB="${libdir}/libopenblas64_.${dlext}";
else
    LOB="$libdir/libopenblas.$dlext"
fi

for sym in  sgemm dgemm spotrf dpotrf strcon dtrcon strtrs dtrtrs ; do
    SYMB_DEFS+=("-D${sym}_=${sym}_64_")
done

export CXXFLAGS="${SYMB_DEFS[@]}"
export LDFLAGS="-L${libdir}"
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_PREFIX_PATH=${libdir} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_MODULE_PATH=$WORKSPACE/srcdir \
    -DMUMPS_INCLUDE_DIR=${includedir} \
    -DMUMPS_LIBRARIES="${libdir}/libdmumps.${dlext}" \
    -DMUMPS_COMMON_LIBRARY="${libdir}/libmumps_common.${dlext}" \
    -DMUMPS_PORD_LIBRARY="${libdir}/libpord.${dlext}" \
    -DMUMPS_MPISEQ_LIBRARY="${libdir}/libmpiseq.${dlext}" \
    -DBLAS_LIBRARIES=${LOB} \
    -DLAPACK_LIBRARIES=${LOB} \
    ..

make
make install
install_license ../LICENSE
"""


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
#platforms = expand_gfortran_versions(platforms)
filter!(p -> !(os(p) == "freebsd"), platforms)
filter!(p -> !(arch(p) == "i686"), platforms)
filter!(p -> !(libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
filter!(p -> !(arch(p) == "powerpc64le"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libqpOASES", :libqpOASES),
    LibraryProduct("libqpOASES_MUMPS", :libqpOASES_MUMPS),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MUMPS_seq_jll",
                uuid="d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"),
                compat="500.700.301"),
    Dependency("OpenBLAS_jll"; compat="0.3.23"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll",
                uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    HostBuildDependency(PackageSpec(; name="CMake_jll"))
    ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9",
    julia_compat="1.9")