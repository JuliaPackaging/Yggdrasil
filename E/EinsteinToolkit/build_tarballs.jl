# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
using BinaryBuilderBase: march
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "EinsteinToolkit"
version = v"2024.11"

# Collection of sources required to complete build
sources = [
    GitSource("https://bitbucket.org/cactuscode/cactus.git", "b11bff7a6af94460d73e6a20ae2242df73e334c9"),
    #TODO GitSource("https://bitbucket.org/einsteintoolkit/manifest.git", "94f70c335eb812aecc59510a9f7cdfdceba97057"),

    GitSource("https://bitbucket.org/cactuscode/cactusbase.git", "49a9d71ec54e97eead7b057bae247f734678ce81"),
    GitSource("https://bitbucket.org/cactuscode/cactusconnect.git", "7a208b0de559749c565f6d3fabbba579cf6ccbac"),
    GitSource("https://bitbucket.org/cactuscode/cactuselliptic.git", "5934bfbaa993d0f41bd673b416a2096d9baf0ea3"),
    GitSource("https://bitbucket.org/cactuscode/cactusexamples.git", "8cc66913ebe8f7dbb6143e7580b624e39e6d7351"),
    GitSource("https://bitbucket.org/cactuscode/cactusio.git", "cb8c7d2960ec53547864bd9a87eb190443f29a59"),
    GitSource("https://bitbucket.org/cactuscode/cactusnumerical.git", "1656493dd917821cf9933c7dac4de8f9d1a28c88"),
    GitSource("https://bitbucket.org/cactuscode/cactuspugh.git", "a8e3236308f968b2cdf9a91a065ed220ddd6aedb"),
    GitSource("https://bitbucket.org/cactuscode/cactuspughio.git", "63f958be245119746095b4c993413ace4650fe62"),
    GitSource("https://bitbucket.org/cactuscode/cactustest.git", "e5fc4370f7ace3352b7b242a5fe8a2ab788fe39f"),
    GitSource("https://bitbucket.org/cactuscode/cactusutils.git", "474e6b1e9cc8005d1cb38878b617a22a2c44b2ca"),
    GitSource("https://bitbucket.org/cactuscode/cactuswave.git", "35443f5eb3cd1086ccb6c4548bcced526caded70"),

    GitSource("https://github.com/einsteintoolkit/Carpet.git", "99c01a80219af62195e9dcc674e436c5f8309dbe"),

    GitSource("https://bitbucket.org/einsteintoolkit/einsteinanalysis.git", "b7d79de8b744005b5513ee6d76822ad7db33a4a8"),
    GitSource("https://bitbucket.org/einsteintoolkit/einsteinbase.git", "db5777d1f921254d3e8d489c5b2e2b1c336113ef"),
    GitSource("https://bitbucket.org/einsteintoolkit/einsteineos.git", "dc6b13d4a835384e2bdca51a4478bd87a3f26676"),
    GitSource("https://bitbucket.org/einsteintoolkit/einsteinevolve.git", "25f1178eb3c2aedfcc92cc460cd2834c6d7369ed"),
    GitSource("https://bitbucket.org/einsteintoolkit/einsteinexamples.git", "a308525882c0072c14a139b2892b035e1bf7fd95"),
    GitSource("https://bitbucket.org/einsteintoolkit/einsteininitialdata.git", "32a4a3d2d4463c10fb2b6a977e0ebbaa75b43034"),
    GitSource("https://bitbucket.org/einsteintoolkit/einsteinutils", "01d568fb7ae258e6822af450353d5a7dc3401168"),
    GitSource("https://github.com/barrywardell/EinsteinExact.git", "79a3aab9527f1ca280639657958fa1e6f724bcad"),

    # GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-BLAS", "93bed30e19f4f09840622d223578aa78639988fe"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-FFTW3", "b259730780518efa6333550963c40cee3455dd2c"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-GSL", "827085fe750ebfc7359f083614a124915883ca5b"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-HDF5", "eeb204b3db68212286641cfe03e7184bcada23f0"),
    # GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-LAPACK", "de8ea278756d69b723141ffeff6985a9ebe14d1e"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-MPI", "8f1b760e35aa8815852e55cdb41779f4583da28f"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-OpenBLAS", "1acebb973c547dc8d1c189a652c88c058b8be486"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-hwloc", "3fb3343feae2c72cb109dbdeb26db280bf731c70"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-libjpeg", "d5c1c5510d18759d7604e5d0bde0e8fd400e664c"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-pthreads", "554c0bbbf54cb3ce3157045f24cfd8af71f27054"),
    GitSource("https://github.com/EinsteinToolkit/ExternalLibraries-zlib", "d15d828036caf2b45a76ea977c1ab47d5658626e"),

    GitSource("https://github.com/GRHayL/GRHayL.git", "6853fe9ae29276621746325d125fa6239460921d"),
    GitSource("https://github.com/GRHayL/GRHayLET.git", "0b1170359736408423e35674713c1d93a8ac1586"),
    GitSource("https://github.com/dboyer7/TOVola.git", "7cf7799ac9746380dffcad29f07a894e992776c1"),
    GitSource("https://github.com/ianhinder/Kranc.git", "b4b2b40103a706a29f8f6b3910110a30afff75aa"),
    GitSource("https://bitbucket.org/llamacode/llama.git", "3733ef58dca5906abbfb3cbffcc19131048f7e71"),
    GitSource("https://bitbucket.org/einsteintoolkit/mclachlan.git", "46157bbd3a716dc36c31fde08b1eaea6cabb1ca4"),
    GitSource("https://bitbucket.org/cactuscode/numerical.git", "535f5975d3ee289400c10c7d761035c63a594a87"),
    GitSource("https://bitbucket.org/einsteintoolkit/pittnullcode.git", "bc662c6dfde296b8a3f2c32c825bd28da0efaded"),
    GitSource("https://bitbucket.org/canuda/lean_public.git", "36c1afcfc6305dea54cae62dd3193567e330bb52"),
    GitSource("https://bitbucket.org/canuda/Proca.git", "79d9ee27a2035e07fa28f67d9fef2bbc6a746912"),
    GitSource("https://bitbucket.org/canuda/Scalar.git", "06b6062740a98f4ec5cfbe8b7d70a165ec87eeda"),
    GitSource("https://github.com/wofti/CactusSgrid.git", "c88af8a391c0c7e235aac0750d3529912d2db0ba"),
    GitSource("https://bitbucket.org/zach_etienne/wvuthorns.git", "7802e89105d8b077e848e62a2e10ed50a79ed8cd"),
    GitSource("https://bitbucket.org/zach_etienne/wvuthorns_diagnostics.git", "378d2a0e90e37b3d9ac477488ccb370bc0ae22fd"),

    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/cactus

# Add "diagnostica data" files used by Formaline
apk add perl-doc

(cd ${WORKSPACE}/srcdir/ExternalLibraries-GSL && atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gsl-detect.patch)
(cd ${WORKSPACE}/srcdir/ExternalLibraries-MPI && atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpi-detect.patch)

# Create source tree structure
mkdir arrangements
(mkdir arrangements/CactusBase && cd arrangements/CactusBase && ln -s ${WORKSPACE}/srcdir/cactusbase/* .)
(mkdir arrangements/CactusConnect && cd arrangements/CactusConnect && ln -s ${WORKSPACE}/srcdir/cactusconnect/* .)
(mkdir arrangements/CactusElliptic && cd arrangements/CactusElliptic && ln -s ${WORKSPACE}/srcdir/cactuselliptic/* .)
(mkdir arrangements/CactusExamples && cd arrangements/CactusExamples && ln -s ${WORKSPACE}/srcdir/cactusexamples/* .)
(mkdir arrangements/CactusIO && cd arrangements/CactusIO && ln -s ${WORKSPACE}/srcdir/cactusio/* .)
(mkdir arrangements/CactusNumerical && cd arrangements/CactusNumerical && ln -s ${WORKSPACE}/srcdir/cactusnumerical/* .)
(mkdir arrangements/CactusPUGH && cd arrangements/CactusPUGH && ln -s ${WORKSPACE}/srcdir/cactuspugh/* .)
(mkdir arrangements/CactusPUGHIO && cd arrangements/CactusPUGHIO && ln -s ${WORKSPACE}/srcdir/cactuspughio/* .)
(mkdir arrangements/CactusTest && cd arrangements/CactusTest && ln -s ${WORKSPACE}/srcdir/cactustest/* .)
(mkdir arrangements/CactusUtils && cd arrangements/CactusUtils && ln -s ${WORKSPACE}/srcdir/cactusutils/* .)
(mkdir arrangements/CactusWave && cd arrangements/CactusWave && ln -s ${WORKSPACE}/srcdir/cactuswave/* .)

(mkdir arrangements/Carpet && cd arrangements/Carpet && ln -s ${WORKSPACE}/srcdir/Carpet/* .)

(mkdir arrangements/EinsteinAnalysis && cd arrangements/EinsteinAnalysis && ln -s ${WORKSPACE}/srcdir/einsteinanalysis/* .)
(mkdir arrangements/EinsteinBase && cd arrangements/EinsteinBase && ln -s ${WORKSPACE}/srcdir/einsteinbase/* .)
(mkdir arrangements/EinsteinEOS && cd arrangements/EinsteinEOS && ln -s ${WORKSPACE}/srcdir/einsteineos/* .)
(mkdir arrangements/EinsteinEvolve && cd arrangements/EinsteinEvolve && ln -s ${WORKSPACE}/srcdir/einsteinevolve/* .)
(mkdir arrangements/EinsteinExact && cd arrangements/EinsteinExact && ln -s ${WORKSPACE}/srcdir/EinsteinExact/* .)
(mkdir arrangements/EinsteinExamples && cd arrangements/EinsteinExamples && ln -s ${WORKSPACE}/srcdir/einsteinexamples/* .)
(mkdir arrangements/EinsteinInitialData && cd arrangements/EinsteinInitialData && ln -s ${WORKSPACE}/srcdir/einsteininitialdata/* .)
(mkdir arrangements/EinsteinUtils && cd arrangements/EinsteinUtils && ln -s ${WORKSPACE}/srcdir/einsteinutils/* .)

(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-FFTW3 FFTW3)
(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-GSL GSL)
(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-HDF5 HDF5)
(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-MPI MPI)
(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-OpenBLAS OpenBLAS)
(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-hwloc hwloc)
(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-libjpeg libjpeg)
(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-pthreads pthreads)
(mkdir -p arrangements/ExternalLibraries && cd arrangements/ExternalLibraries && ln -s ${WORKSPACE}/srcdir/ExternalLibraries-zlib zlib)

(mkdir -p arrangements/GRHayL && cd arrangements/GRHayL && ln -s ${WORKSPACE}/srcdir/GRHayL/implementations/* .)
(mkdir -p arrangements/GRHayLET && cd arrangements/GRHayLET && ln -s ${WORKSPACE}/srcdir/GRHayLET/* .)
(mkdir -p arrangements/GRHayLET && cd arrangements/GRHayLET && ln -s ${WORKSPACE}/srcdir/TOVola/* .)

(mkdir -p arrangements/KrancNumericalTools && cd arrangements/KrancNumericalTools && ln -s ${WORKSPACE}/srcdir/Kranc/Auxiliary/Cactus/KrancNumericalTools/* .)

(mkdir arrangements/Llama && cd arrangements/Llama && ln -s ${WORKSPACE}/srcdir/llama/* .)
(mkdir arrangements/McLachlan && cd arrangements/McLachlan && ln -s ${WORKSPACE}/srcdir/mclachlan/* .)
(mkdir arrangements/Numerical && cd arrangements/Numerical && ln -s ${WORKSPACE}/srcdir/numerical/* .)
(mkdir arrangements/PITTNullCode && cd arrangements/PITTNullCode && ln -s ${WORKSPACE}/srcdir/pittnullcode/* .)
(mkdir arrangements/Lean && cd arrangements/Lean && ln -s ${WORKSPACE}/srcdir/lean_public/* .)
(mkdir arrangements/Proca && cd arrangements/Proca && ln -s ${WORKSPACE}/srcdir/Proca/* .)
(mkdir arrangements/Scalar && cd arrangements/Scalar && ln -s ${WORKSPACE}/srcdir/Scalar/* .)
(mkdir arrangements/CactusSgrid && cd arrangements/CactusSgrid && ln -s ${WORKSPACE}/srcdir/CactusSgrid/* .)
(mkdir arrangements/WVUThorns && cd arrangements/WVUThorns && ln -s ${WORKSPACE}/srcdir/wvuthorns/* .)
(mkdir arrangements/WVUThorns_Diagnostics && cd arrangements/WVUThorns_Diagnostics && ln -s ${WORKSPACE}/srcdir/wvuthorns_diagnostics/* .)

# Use `HAVE-GIT=false` to disable Formaline using git
make sim-config PROMPT=config-only CROSS_COMPILE=yes options=${WORKSPACE}/srcdir/files/desert.cfg THORNLIST=${WORKSPACE}/srcdir/files/desert.th export HAVE-GIT=false
make -j${nproc} sim HAVE-GIT=false
make -j${nproc} sim-utils HAVE-GIT=false

install -Dvm 755 exe/cactus_sim "${bindir}/cactus_sim"

utils='
    RNS
    RNS_readID
    Riemann1d
    ascii_output
    carpet2xgraph
    fftwfilter
    findlast
    hdf5_convert_from_carpetiohdf5
    hdf5_double_to_single
    hdf5_extract
    hdf5_merge
    hdf5_recombiner
    hdf5_slicer
    hdf5toascii_slicer
    hdf5tobinary_slicer
    printtime
    readmeta
    setmeta
'
for util in ${utils}; do
    install -Dvm 755 "exe/sim/${util}" "${bindir}/cactus/${util}"
done

# TODO: `Warning: bin/cactus/RNS: Linked library libcrypt.so.1 could not be resolved and could not be auto-mapped`

# TODO: collect all license files
install_license COPYRIGHT
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)
platforms = expand_microarchitectures(platforms, ["x86_64", "avx2", "avx512"])

# Disable unsupported platforms
filter!(platforms) do p
    # Internal compiler error
    Sys.islinux(p) && arch(p) == "aarch64" && libgfortran_version(p) <= v"4" && return false
    # SIMD vectorization not supported
    Sys.islinux(p) && arch(p) == "powerpc64le" && libgfortran_version(p) <= v"4" && return false
    # SIMD vectorization broken: `__m128i`, `_mm_castsi128_ps` are not found.
    # Maybe we detect or select the wrong architecture in thorn CactusUtils/Vectors?
    Sys.isbsd(p) && arch(p) == "x86_64" && march(p) == "x86_64" && return false
    # <fpu_control.h> does not exist
    libc(p) == "musl" && return false
    # Impossible compiler constraints
    Sys.islinux(p) && arch(p) == "x86_64" && libgfortran_version(p) == v"3" && march(p) == "avx512" && return false
    # `ld: unknown option: -fopenmp`
    # TODO: Fix this.
    Sys.isapple(p) && return false
    # `clang++: error: unable to find library -lg2c`
    # TODO: Fix this.
    Sys.isfreebsd(p) && return false
    # MPI not found
    Sys.iswindows(p) && return false

    return true
end

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("cactus_sim", :cactus_sim),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems)
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
    Dependency("FFTW_jll"; compat="3.3.11"),
    Dependency("GSL_jll"; compat="2.8.1"),
    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("Hwloc_jll"; compat="2.12.0"),
    Dependency("JpegTurbo_jll"; compat="3.1.1"),
    Dependency("OpenBLAS32_jll"; compat="0.3.29"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"6")
