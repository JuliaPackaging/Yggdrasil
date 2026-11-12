using BinaryBuilder

name = "Sollya"
version = v"8.0.0"

sources = [
    ArchiveSource("https://www.sollya.org/releases/sollya-$(version.major).$(version.minor)/sollya-$(version.major).$(version.minor).tar.bz2",
                  "5f5af648424084c1dc075ff103912905ff9bd6bf97187a922d0374939964c1e9"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/sollya*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gettimeofday.patch

options=(
    --prefix=${prefix}
    --build=${MACHTYPE}
    --host=${target}
    --enable-static=no
    --with-gmp
    --with-mpfr
    --with-fplll
    --with-z
    --with-mpfi
    --with-xml2
)

./configure ${options[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# fplll is not available on Windows
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsollya", :libsollya),
    ExecutableProduct("sollya", :sollya),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("MPFI_jll"; compat="1.5.6"),
    Dependency("MPFR_jll"; compat="4.2.0"),
    Dependency("XML2_jll"; compat="~2.13.6"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("dlfcn_win32_jll"; compat="1.4.1", platforms=filter(Sys.iswindows, platforms)),
    Dependency("fplll_jll"; compat="5.5.0"),
]

# Build the tarballs.
# We need at least GCC 5 for newer C and C++ features.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")
