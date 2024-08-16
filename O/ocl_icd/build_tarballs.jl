using BinaryBuilder

name = "ocl_icd"
version = v"2.3.2"
sources = [
    GitSource("https://github.com/OCL-dev/ocl-icd.git", "fdde6677b21329432db8b481e2637cd10f7d3cb2")
]

script = raw"""
apk add ruby

cd ${WORKSPACE}/srcdir/ocl-icd
./bootstrap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j all
make install
"""

platforms = supported_platforms()
filter!(p -> libc(p) == "glibc", platforms)

products = [
    LibraryProduct(["libOpenCL", "OpenCL"], :libocl_icd),
    FileProduct("include/ocl_icd.h", :ocl_icd_h)
]


dependencies = [
    BuildDependency("OpenCL_Headers_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")