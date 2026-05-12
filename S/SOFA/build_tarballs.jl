using BinaryBuilder, Pkg

name = "SOFA"
version = v"2019.07.22"   # Match the SOFA release date

sources = [
    ArchiveSource(
        "https://github.com/JuliaAstro/SOFA.jl/releases/download/sofa-c-20190722/sofa_c-20190722.tar.gz",
        "c4434822ef7428962d49c56dc417b61f691f47cf39187abf08f1f785f8297346",
    ),
]

# Build a shared library from all .c files in c/src.
# Works for *-linux-*, *-apple-darwin, *-mingw*, *-freebsd*, etc.
script = raw"""
cd $WORKSPACE/srcdir/sofa

# Compile every SOFA .c into a shared library.
# -fPIC is harmless on mingw (ignored) and required on ELF/Mach-O targets.
# Skip t_sofa_c.c — it's a test driver with main() that we don't want in the library.
$CC -O2 -fPIC -shared -o libsofa_c.${dlext} $(ls *.c | grep -v '^t_sofa_c\.c$') -lm

mkdir -p ${libdir} ${includedir}/sofa
mv libsofa_c.${dlext} ${libdir}/
cp sofa.h sofam.h ${includedir}/sofa/

# SOFA's licence text lives in the .c headers; ship it explicitly.
install_license sofa.h
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libsofa_c", :libsofa_c),
]

dependencies = Dependency[]   # libm comes from libc

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.10")
