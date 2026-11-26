using BinaryBuilder, Pkg

name = "SDPA_GMP"
version = v"7.1.3"

sources = [
    GitSource("https://github.com/nakatamaho/sdpa-gmp.git",
              "ca110db5ea1cc46e811b70dfea9cbb25db74448d"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/sdpa-gmp
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/full-precision-output.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/no-sys-times.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/binary-mode-data-file.patch
sed -i -e 's/-march[^ ]*//g' Makefile.am
autoreconf -fi

# Upstream marks its OpenMP support as temporary, and with it SDPA-DD's results depend on the thread count.
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-openmp \
    --with-system-gmp \
    --with-gmp-includedir=${includedir} \
    --with-gmp-libdir=${libdir}

# The bundled SPOOLES passes NULL as an int, an error in clang. Its makefiles ignore CFLAGS.
make -j${nproc} CC="${CC} -Wno-int-conversion"
make install

install_license COPYING
install_license external/spooles/work/internal/spooles.*.html
# MPLAPACK carries its BSD licence only in its source file headers.
sed -n '/^ \* Copyright (c) 2008/,/SUCH DAMAGE\./p' mplapack/Rgemv.cpp > LICENSE.MPLAPACK
test -s LICENSE.MPLAPACK
install_license LICENSE.MPLAPACK
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
# MPLAPACK's mplapackint is int64_t, which is long long on 32-bit targets; gmpxx cannot convert it to mpf_class.
filter!(p -> nbits(p) == 64, platforms)

products = [
    ExecutableProduct("sdpa_gmp", :sdpa_gmp),
]

dependencies = [
    # Julia 1.10.0 ships 1.0.5. 1.3.0 is the oldest release with artifacts for both libgfortran3
    # (the GCC this builds with) and riscv64.
    Dependency("CompilerSupportLibraries_jll", v"1.3.0"; compat="1.0.5"),
    Dependency("GMP_jll"; compat="6.2.1"),
]

# GCC 6 is the oldest whose default C++ standard provides <chrono>, which sdpa_tool.cpp includes.
# SDPAFamily.jl, the package that uses this JLL, requires Julia 1.10.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"6")
