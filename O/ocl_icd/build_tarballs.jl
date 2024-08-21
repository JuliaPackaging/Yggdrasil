using BinaryBuilder

name = "ocl_icd"
version = v"2.3.2"
sources = [
    GitSource("https://github.com/OCL-dev/ocl-icd.git", "fdde6677b21329432db8b481e2637cd10f7d3cb2"),
    DirectorySource("$(pwd())/patches")
]

script = raw"""
apk add ruby

cd ${WORKSPACE}/srcdir/ocl-icd

# Copy License
mkdir -p ${WORKSPACE}/destdir/share/licenses/ocl_icd
cp COPYING ${WORKSPACE}/destdir/share/licenses/ocl_icd

# Fix build for windows based on 
# https://cygwin.com/cgit/cygwin-packages/ocl-icd/tree/ocl-icd-2.3.2-1.src.patch
if [[ "${target}" == *-w64-* ]]; then
    git apply ../cygwin.patch
fi

./bootstrap

# Fix rpl_malloc error with musl
if [[ "${target}" == *-musl* ]]; then
    sed -i '/AC_FUNC_MALLOC/d' ./configure.ac
    sed -i '/AC_FUNC_REALLOC/d' ./configure.ac
fi
if [[ "${target}" == *-apple-* ]]; then
    sed -i '/AC_FUNC_MALLOC/d' ./configure.ac
    sed -i '/AC_FUNC_REALLOC/d' ./configure.ac
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target}
make -j all
make install
"""

platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

products = [
    LibraryProduct(["libOpenCL", "OpenCL"], :libocl_icd),
    FileProduct("include/ocl_icd.h", :ocl_icd_h)
]


dependencies = [
    Dependency("dlfcn_win32_jll", platforms=filter(Sys.iswindows, platforms))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")