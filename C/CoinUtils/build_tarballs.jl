# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CoinUtils"
version = v"2.11.4"

# Collection of sources required to complete build
sources = [
    # GitSource("https://github.com/coin-or/CoinUtils.git", "d4f2b7f1897b67da6929ab42aa6b1962a388c5b9"),
    ArchiveSource("https://github.com/coin-or/CoinUtils/archive/releases/2.11.4.tar.gz",
                  "d4effff4452e73356eed9f889efd9c44fe9cd68bd37b608a5ebb2c58bd45ef81"),
    # DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils-releases-2.11.4

# Remove wrong libtool files
rm -f /opt/${target}/${target}/lib*/*.la

# if [[ "${target}" == *-musl* ]]; then
#     # This is to fix the following error:
#     #    node_heap.cpp:11:22: fatal error: execinfo.h: No such file or directory
#     #     #include <execinfo.h>
#     # `execinfo.h` is GlibC-specific, not Linux-specific
#     atomic_patch -p1 "${WORKSPACE}/srcdir/patches/glibc_specific.patch"
# fi

OPENBLAS=(-lopenblas)
CPPFLAGS=()
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    OPENBLAS=(-lopenblas64_)
  syms=(caxpy cbdsqr ccopy cdotc cdotu cgbmv cgbtrf cgemm cgemv cgerc cgeru cgetrf cgetrs chbmv chemm chemv cher cher2 cher2k cherk chetrd clacgv clacpy cladiv clanhs clarfg clartg claset clasr classq claswp cpbtrf cpotrf cpttrf crot csbmv cscal csscal cswap csymm csyr2k csyrk ctbtrs ctrmm ctrmv ctrsm ctrsv ctrtrs dasum daxpy dsbmv dbdsqr dcopy ddot dgbmv dgbtrf dgemm dgemv dger dgetrf dgetrs dhbmv disnan dlabad dlacpy dlae2 dlaebz dlaed4 dlaev2 dlagtf dlagts dlahqr dlamc3 dlamch dlange dlanst dlanv2 dlapy2 dlapy3 dlaqr0 dlaqr1 dlaqr3 dlaqr4 dlarfg dlarfx dlarnv dlarra dlarrb dlarrc dlarrd dlarrk dlarrv dlartg dlaruv dlascl dlaset dlasq2 dlasr dlasrt dlassq dlaswp dlasy2 dnrm2 dpbtrf dpotrf dpttrf drot dscal dstedc dsteqr dsterf dswap dsymm dsymv dsyr dsyr2 dsyr2k dsyrk dsytrd dtbtrs dtrmm dtrmv dtrsm dtrsv dtrtrs dzasum dznrm2 dzsum1 icamax icmax1 idamax ieeeck ilaenv isamax izamax izmax1 lsame lsamen sasum saxpy sbdsqr scasum scnrm2 scopy scsum1 sdot sgbmv sgbtrf sgemm sgemv sger sgetrf sgetrs shbmv sisnan slabad slacpy slae2 slaebz slaed4 slaev2 slagtf slagts slahqr slamc3 slamch slange slanst slanv2 slapy2 slapy3 slaqr0 slaqr1 slaqr3 slaqr4 slarfg slarfx slarnv slarra slarrb slarrc slarrd slarrk slarrv slartg slaruv slascl slaset slasq2 slasr slasrt slassq slaswp slasy2 snrm2 spbtrf spotrf spttrf srot ssbmv sscal sstedc ssteqr ssterf sswap ssymm ssymv ssyr ssyr2 ssyr2k ssyrk ssytrd stbtrs strmm strmv strsm strsv strtrs xerbla zaxpy zbdsqr zcopy zdotc zdotu zdscal zgbmv zgbtrf zgemm zgemv zgerc zgeru zgetrf zgetrs zhbmv zhemm zhemv zher zher2 zher2k zherk zhetrd zlacgv zlacpy zladiv zlanhs zlarfg zlartg zlaset zlasr zlassq zlaswp zpbtrf zpotrf zpttrf zrot zdbmv zscal zswap zsymm zsyr2k zsyrk ztbtrs ztrmm ztrmv ztrsm ztrsv ztrtrs)
  for sym in ${syms[@]}
  do
    CPPFLAGS+=("-D${sym}=${sym}_64")
  done
fi

CPPFLAGS="${CPPFLAGS[@]}" ./configure --prefix=${prefix} --with-blas-lib="${OPENBLAS[@]}" --with-lapack-lib="${OPENBLAS[@]}" --host=${target})
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
# platforms = [
#  # Linux(:i686, libc=:glibc)
#  # Linux(:x86_64, libc=:glibc)
#  # # Linux(:aarch64, libc=:glibc)  # fails
#  # Linux(:armv7l, libc=:glibc, call_abi=:eabihf)
#  # # Linux(:powerpc64le, libc=:glibc) # fails
#  # Linux(:i686, libc=:musl)
#  # Linux(:x86_64, libc=:musl)
#  Linux(:aarch64, libc=:musl)  # fails
#  # # Linux(:armv7l, libc=:musl, call_abi=:eabihf)  # fails
#  # MacOS(:x86_64)
#  # FreeBSD(:x86_64)
#  # Windows(:i686)  # fails
#  # Windows(:x86_64)  # fails
# ]

# The products that we will ensure are always built
products = [
    LibraryProduct("libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
