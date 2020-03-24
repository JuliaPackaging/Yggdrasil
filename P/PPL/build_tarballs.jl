# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Collection of sources required to build pplBuilder
sources = [
    ArchiveSource("http://www.bugseng.com/products/ppl/download/ftp/releases/1.2/ppl-1.2.tar.bz2", "2d470b0c262904f190a19eac57fb5c2387b1bfc3510de25a08f3c958df62fdf1"),
    DirectorySource("./bundled")
]
name = "ppl"
version = v"1.2"

# Bash recipe for building across all platforms
script = raw"""
cd ppl-1.2
atomic_patch -p1 ../patches/patch-v1.2.diff
# avoid libtool problems (always in lib and not in libdir on mingw)
rm -f ${prefix}/lib/libgmpxx.la
# correct powerpc linker option:
sed -i -e 's/elf64ppc/elf64lppc/g' configure
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} --enable-interfaces=c,cxx --enable-static=no --enable-documentation=no --with-gmp=${prefix} --enable-shared=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("ppl_lcdd", :ppl_lcdd)
    ExecutableProduct("ppl_pips", :ppl_pips)
    LibraryProduct("libppl", :libppl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
