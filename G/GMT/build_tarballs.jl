using BinaryBuilder, Pkg

name = "GMT"
version = v"6.7.3"
GSHHG_VERSION = "2.3.7"
DCW_VERSION = "2.2.0"

sources = [
    GitSource("https://github.com/GenericMappingTools/gmt",
              "3ca89b546dc726a159e58d4f06e06349930ca4ac"),
    ArchiveSource("https://github.com/GenericMappingTools/gshhg-gmt/releases/download/$(GSHHG_VERSION)/gshhg-gmt-$(GSHHG_VERSION).tar.gz",
                  "9bb1a956fca0718c083bef842e625797535a00ce81f175df08b042c2a92cfe7f"),
    ArchiveSource("https://github.com/GenericMappingTools/DCW-type-files/releases/download/new/dcw-gmt-$(DCW_VERSION)_plus.tar.gz",
                  "096e64535a7e3cc1f870a9d6a569b5bac63040b602d04f4077d41b62ec0f7bbb"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/gmt
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHAVE_QSORT_R_GLIBC=False \
    -DBUILD_IMGTEXTURE=TRUE \
    -DHAVE___BUILTIN_BSWAP16=False \
    -DHAVE___BUILTIN_BSWAP32=False \
    -DHAVE___BUILTIN_BSWAP64=False \
    -DGMT_ENABLE_OPENMP=True \
    -DJULIA_GHOST_JLL=True \
    -DGSHHG_PATH=$(echo ${WORKSPACE}/srcdir/gshhg-gmt-*) \
    -DDCW_PATH=$(echo ${WORKSPACE}/srcdir/dcw-gmt-*)
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE.TXT
"""

platforms = supported_platforms()
# OpenBLAS32_jll and LAPACK32_jll have no riscv64 build that supports Julia 1.10
filter!(p -> arch(p) != "riscv64", platforms)
# the musl sysroot has no qsort_r
filter!(p -> libc(p) != "musl", platforms)
# GMT's qsort_r calls do not compile against FreeBSD 14's qsort_r
filter!(!Sys.isfreebsd, platforms)
# HDF5_jll (through GDAL_jll and NetCDF_jll) resolves to its OpenMPI build here, and OpenMPI_jll has none
filter!(p -> !(Sys.islinux(p) && arch(p) in ("i686", "armv7l")), platforms)

products = [
    LibraryProduct(["libpostscriptlight", "postscriptlight"], :libpostscriptlight),
    LibraryProduct(["libgmt", "gmt"], :libgmt),
    ExecutableProduct("gmt", :gmt),
]

dependencies = [
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"); compat="7.73, 8"),
    Dependency("NetCDF_jll"; compat="401.1000.101"),
    Dependency("PROJ_jll"; compat="902.600"),
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"); compat="305.1300.301"),
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"); compat="3.3.11"),
    Dependency(PackageSpec(name="PCRE_jll", uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc"); compat="8.45.1"),
    Dependency(PackageSpec(name="LAPACK32_jll", uuid="17f450c3-bd24-55df-bb84-8c51b4b939e3"); compat="3.12.0"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"); compat="0.3.24"),
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"); compat="2.84.0"),
    Dependency(PackageSpec(name="Ghostscript_jll", uuid="61579ee1-b43e-5ca0-a5da-69d92c66a64b"); compat="9.55.1"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               compat="1.0.5", platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               compat="19.1.7 - 23", platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"11")
