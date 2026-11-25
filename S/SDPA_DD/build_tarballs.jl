using BinaryBuilder, Pkg

name = "SDPA_DD"
version = v"7.1.3"

sources = [
    GitSource("https://github.com/nakatamaho/sdpa-dd.git",
              "6eaad8d9abff929bf8abc55ea166cbb2b09d07df"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/sdpa-dd
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/full-precision-output.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/no-sys-times.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/binary-mode-data-file.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/static-qd-on-macos.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/qd-no-fma.patch
autoreconf -fi

# QD and SPOOLES are the copies upstream bundles, linked statically. QD_jll has no Windows build;
# with one, --with-system-qd could use it.
# With OpenMP, MPLAPACK's dot products add per-thread partial sums in the order the threads finish,
# so results vary between runs.
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-openmp

# The bundled QD's libtool sets up a Fortran tag when FC is set, even with --enable-fortran=no, and
# for mingw takes that compiler for MSVC and names the library libqd.lib, which -lqd does not find.
unset FC
# The bundled SPOOLES passes NULL as an int, an error in clang. Its makefiles ignore CFLAGS.
make -j${nproc} CC="${CC} -Wno-int-conversion"
# Not make install: it recurses into external/qd, whose Makefile.am has no rule for the stamp its
# install target needs.
make install-binPROGRAMS

install_license COPYING
install_license external/spooles/work/internal/spooles.*.html
install -vm 644 external/qd/work/internal/qd-*/COPYING LICENSE.QD
install_license LICENSE.QD
# MPLAPACK carries its BSD licence only in its source file headers.
sed -n '/^ \* Copyright (c) 2008/,/SUCH DAMAGE\./p' mplapack/Rgemv.cpp > LICENSE.MPLAPACK
test -s LICENSE.MPLAPACK
install_license LICENSE.MPLAPACK
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("sdpa_dd", :sdpa_dd),
]

dependencies = [
    # Julia 1.10.0 ships 1.0.5. 1.3.0 is the oldest release with artifacts for both libgfortran3
    # (the GCC this builds with) and riscv64.
    Dependency("CompilerSupportLibraries_jll", v"1.3.0"; compat="1.0.5"),
]

# GCC 6 is the oldest whose default C++ standard provides <chrono>, which sdpa_tool.cpp includes.
# SDPAFamily.jl, the package that uses this JLL, requires Julia 1.10.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"6")
