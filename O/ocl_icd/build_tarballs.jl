# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder

name = "ocl_icd"
version = v"2.3.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/OCL-dev/ocl-icd.git",
              "fdde6677b21329432db8b481e2637cd10f7d3cb2"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
apk add ruby

cd ${WORKSPACE}/srcdir/ocl-icd
install_license COPYING

# Fix build for Windows based on
# https://cygwin.com/cgit/cygwin-packages/ocl-icd/tree/ocl-icd-2.3.2-1.src.patch
if [[ "${target}" == *-w64-* ]]; then
    atomic_patch -p2 ../patches/ocl-icd-2.3.2-1.src.patch
fi

./bootstrap

# Fix rpl_malloc for musl
if [[ "${target}" == *-musl* ]] || [[ "${target}" == *-apple-* ]]; then
    sed -i '/AC_FUNC_MALLOC/d' ./configure.ac
    sed -i '/AC_FUNC_REALLOC/d' ./configure.ac
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}

make -j${nproc} all
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libOpenCL", "OpenCL"], :libocl_icd),
    FileProduct("include/ocl_icd.h", :ocl_icd_h)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("dlfcn_win32_jll", platforms=filter(Sys.iswindows, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
