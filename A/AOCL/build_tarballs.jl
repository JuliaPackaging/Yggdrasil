using BinaryBuilder, Pkg

name = "AOCL"
version = v"5.1.0"
sources = [
    ArchiveSource("https://download.amd.com/developer/eula/blas/blas-5-1/aocl-blis-linux-gcc-5.1.0.tar.gz",
                  "43dcc5efe9a73d7065e4a5faf9071f92624d71a033fa56f2d74e775df3ab100a"),
    ArchiveSource("https://download.amd.com/developer/eula/libflame/libflame-5-1/aocl-libflame-linux-gcc-5.1.0.tar.gz",
                  "95da66503c2b2160552824109d51a6fc24f1d176a7bdcec3e25f866ce080c777"),
    ArchiveSource("https://download.amd.com/developer/eula/utils/utils-5-1/aocl-utils-linux-gcc-5.1.0.tar.gz",
                  "c2b7316d364deb933e440f5d37cd7abeeb5cce9faf97efd1d0bc05c264ac93a8"),
    GitSource("https://github.com/amd/AOCL_jll.jl.git",
              "d3bffce6129bd77cde3f68adb9b03a44b82cfba2"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/

# install the LP64 binaries (renamed to avoid soname collision)
# ------------------------------------------------------------------------------
install -Dvm 755 amd-blis/lib/LP64/libblis-mt.so.5.1.0 ${libdir}/libblis-mt32.so
install -Dvm 755 amd-libflame/lib/LP64/libflame.so ${libdir}/libflame32.so

# change the LP64 binaries' soname
# ------------------------------------------------------------------------------
patchelf --set-soname libblis-mt32.so ${libdir}/libblis-mt32.so
patchelf --set-soname libflame32.so ${libdir}/libflame32.so

# ensure that libflame32 actually depends on the renamed library
# ------------------------------------------------------------------------------
patchelf --replace-needed libblis-mt.so.5 libblis-mt32.so ${libdir}/libflame32.so

# install the ILP64 binaries
# ------------------------------------------------------------------------------
install -Dvm 755 amd-blis/lib/ILP64/libblis-mt.so.5.1.0 ${libdir}/libblis-mt.so
install -Dvm 755 amd-libflame/lib/ILP64/libflame.so ${libdir}/libflame.so

# change the soname for blis for consistency (and update libflame)
patchelf --set-soname libblis-mt.so ${libdir}/libblis-mt.so
patchelf --replace-needed libblis-mt.so.5 libblis-mt.so ${libdir}/libflame.so

# install the AOCL-UTILS library
# ------------------------------------------------------------------------------
install -Dvm 755 amd-utils/lib/libaoclutils.so ${libdir}/libaoclutils.so

cd ${WORKSPACE}/srcdir/AOCL_jll.jl/recipe/bundled/licenses
install_license 'LICENSE File for AOCL-BLIS v.5.1.pdf'
install_license 'Third_Party_Notices_AOCL-BLIS v.5.1.pdf'
install_license 'LICENSE File for AOCL-LIBFLAME v.5.1.pdf'
install_license 'Third_Party_Notices_AOCL-LIBFLAME v.5.1.pdf'
install_license 'LICENSE File for AOCL-Utils v.5.1.pdf'
install_license 'Third_Party_Notices_AOCL-Utils v.5.1.pdf'
"""

platforms = [ Platform("x86_64", "linux"; libc="glibc", cxxstring_abi=:cxx11) ]

products = [
    # LP64
    LibraryProduct("libblis-mt32", :aocl_blas_lp64),
    LibraryProduct("libflame32", :aocl_lapack_lp64),
    # ILP64
    LibraryProduct("libblis-mt", :aocl_blas_ilp64),
    LibraryProduct("libflame", :aocl_lapack_ilp64),
    # COMMON
    LibraryProduct("libaoclutils", :aocl_utils),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
