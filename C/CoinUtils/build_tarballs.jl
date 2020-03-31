using BinaryBuilder

name = "CoinUtils"
version = v"2.11.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/CoinUtils.git", "f709081c9b57cc2dd32579d804b30689ca789982"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils*

# Remove wrong libtool files
rm -f /opt/${target}/${target}/lib*/*.la

if [[ "${target}" == *-musl* ]]; then
    # This is to fix the following error:
    #    node_heap.cpp:11:22: fatal error: execinfo.h: No such file or directory
    #     #include <execinfo.h>
    # `execinfo.h` is GlibC-specific, not Linux-specific
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/glibc_specific.patch"
fi

if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
  OPENBLAS=(-lopenblas64_)
  syms=(caxpy cbdsqr ccopy cdotc cdotu cgbmv cgbtrf cgemm cgemv cgerc cgeru cgetrf cgetrs chbmv chemm chemv cher cher2 cher2k cherk chetrd clacgv clacpy cladiv clanhs clarfg clartg claset clasr classq claswp cpbtrf cpotrf cpttrf crot csbmv cscal csscal cswap csymm csyr2k csyrk ctbtrs ctrmm ctrmv ctrsm ctrsv ctrtrs dasum daxpy dsbmv dbdsqr dcopy ddot dgbmv dgbtrf dgemm dgemv dger dgetrf dgetrs dhbmv disnan dlabad dlacpy dlae2 dlaebz dlaed4 dlaev2 dlagtf dlagts dlahqr dlamc3 dlamch dlange dlanst dlanv2 dlapy2 dlapy3 dlaqr0 dlaqr1 dlaqr3 dlaqr4 dlarfg dlarfx dlarnv dlarra dlarrb dlarrc dlarrd dlarrk dlarrv dlartg dlaruv dlascl dlaset dlasq2 dlasr dlasrt dlassq dlaswp dlasy2 dnrm2 dpbtrf dpotrf dpttrf drot dscal dstedc dsteqr dsterf dswap dsymm dsymv dsyr dsyr2 dsyr2k dsyrk dsytrd dtbtrs dtrmm dtrmv dtrsm dtrsv dtrtrs dzasum dznrm2 dzsum1 icamax icmax1 idamax ieeeck ilaenv isamax izamax izmax1 lsame lsamen sasum saxpy sbdsqr scasum scnrm2 scopy scsum1 sdot sgbmv sgbtrf sgemm sgemv sger sgetrf sgetrs shbmv sisnan slabad slacpy slae2 slaebz slaed4 slaev2 slagtf slagts slahqr slamc3 slamch slange slanst slanv2 slapy2 slapy3 slaqr0 slaqr1 slaqr3 slaqr4 slarfg slarfx slarnv slarra slarrb slarrc slarrd slarrk slarrv slartg slaruv slascl slaset slasq2 slasr slasrt slassq slaswp slasy2 snrm2 spbtrf spotrf spttrf srot ssbmv sscal sstedc ssteqr ssterf sswap ssymm ssymv ssyr ssyr2 ssyr2k ssyrk ssytrd stbtrs strmm strmv strsm strsv strtrs xerbla zaxpy zbdsqr zcopy zdotc zdotu zdscal zgbmv zgbtrf zgemm zgemv zgerc zgeru zgetrf zgetrs zhbmv zhemm zhemv zher zher2 zher2k zherk zhetrd zlacgv zlacpy zladiv zlanhs zlarfg zlartg zlaset zlasr zlassq zlaswp zpbtrf zpotrf zpttrf zrot zdbmv zscal zswap zsymm zsyr2k zsyrk ztbtrs ztrmm ztrmv ztrsm ztrsv ztrtrs)
  for sym in ${syms[@]}
  do
    CPPFLAGS+=("-D${sym}=${sym}_64")
  done
  CPPFLAGS+="-Dipfint=long"
else
  OPENBLAS=(-lopenblas)
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-glpk --with-glpk-lib="-lglpk" --with-blas-lib="${OPENBLAS[@]}" CPPFLAGS="${CPPFLAGS[@]}" --with-lapack --with-lapack-lib="${OPENBLAS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = expand_cxxstring_abis(supported_platforms())
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("OpenBLAS_jll"),
    Dependency("GLPK_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
