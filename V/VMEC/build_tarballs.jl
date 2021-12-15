using BinaryBuilder

name = "VMEC"
version = v"1.0.0"

sources = [
    ArchiveSource("https://gitlab.com/wistell/VMEC2000/-/archive/v1.0.0.tar", "179761d5f02cb530fbf6da4121c394a1d585c49c24391ebd87fe5c014e0addcf"),
]

script = raw"""
mkdir -p ${libdir}
cd ${WORKSPACE}/srcdir/VMEC2000*
make USE_MKL=1
install -m755 lib/libvmec_mkl.so ${libdir}
make USE_MKL=1 vmec_clean ; make USE_MKL=0
install -m755 lib/libvmec_openblas.so ${libdir}
make USE_MKL=0 vmec_clean
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc", libgfortran_version="4.0.0"),
    Platform("x86_64", "linux"; libc = "glibc", libgfortran_version="5.0.0"),
]
#platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libvmec_mkl", :libvmec_mkl, dont_dlopen = true),
    LibraryProduct("libvmec_openblas", :libvmec_openblas, dont_dlopen = true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MPICH_jll"),
    Dependency("OpenBLAS_jll", v"0.3.17"),
    Dependency("SCALAPACK_jll"),
    Dependency("MKL_jll"),
    Dependency("oneTBB_jll"),
    Dependency("NetCDF_jll"),
    Dependency("NetCDFF_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
