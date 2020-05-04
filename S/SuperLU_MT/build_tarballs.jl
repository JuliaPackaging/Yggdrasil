# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SuperLU_MT"
version = v"3.1"

# Collection of sources required to build Elemental
sources = [
    ArchiveSource("https://portal.nersc.gov/project/sparse/superlu/superlu_mt_3.1.tar.gz",
                  "407b544b9a92b2ed536b1e713e80f986824cf3016657a4bfc2f3e7d2a76ecab6"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd SuperLU_MT_*

atomic_patch -p1 ../patches/01-fix-makefiles.patch

# Weird sed delimiters because some variables contain slashes.
sed -i "s~^BLASLIB.*~BLASLIB = -L$libdir -lopenblas~" make.inc
sed -i "s~^CC.*~CC = $CC~" make.inc
sed -i "s~^FORTRAN.*~FORTRAN = $FC~" make.inc

if [[ "$nbits" != 64 ]]; then
  sed -i "s/^CFLAGS.*+= -D_LONGINT$//" make.inc
fi

make superlulib "-j$nproc"
cp lib/libsuperlu_mt_PTHREAD.so "$libdir"
cp SRC/*.h "$prefix/include"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuperlu_mt_PTHREAD", :libsuperlu_mt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
