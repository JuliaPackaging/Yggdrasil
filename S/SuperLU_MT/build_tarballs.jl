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

cp MAKE_INC/make.linux.openmp make.inc

atomic_patch -p1 ../patches/01-fix-makefile.patch

# Build object files suitable for a shared library, and link the libraries we need.
echo "CFLAGS += -fPIC -fopenmp \$(BLASLIB)" >> make.inc
echo "NOOPTS += -fPIC -fopenmp \$(BLASLIB)" >> make.inc

# On 64-bit systems, use 64-bit integers for indexing.
if [[ "$nbits" == 64 ]]; then
  echo "CFLAGS += -D_LONGINT" >> make.inc
fi

# We need to add a suffix to BLAS symbols.
SYMBOLS=()
for fun in isamax sasum saxpy scopy strsv idamax dasum daxpy dcopy dtrsv ctrsv ztrsv; do
  SYMBOLS+=("-D$fun=${fun}_")
done
echo "CFLAGS += ${SYMBOLS[@]}" >> make.inc

# Don't use 64-bit integers on non-64-bit systems.
if [[ "$nbits" != 64 ]]; then
  sed -i "s/^CFLAGS.*+= -D_LONGINT$//" make.inc
fi

# Clang doesn't play nicely with OpenMP.
if [[ "$target" == *-freebsd* || "$target" == *-apple-* ]]; then
  CC=gcc
fi

# Weird sed delimiters because some variables contain slashes.
sed -i "s~^BLASLIB.*~BLASLIB = -L$libdir -lopenblas~" make.inc
sed -i "s~^CC.*~CC = $CC~" make.inc
sed -i "s~^FORTRAN.*~FORTRAN = $FC~" make.inc

make superlulib "-j$nproc"
cp lib/single "$libdir/libsuperlumts.$dlext"
cp lib/double "$libdir/libsuperlumtd.$dlext"
cp lib/complex "$libdir/libsuperlumtc.$dlext"
cp lib/complex16 "$libdir/libsuperlumtz.$dlext"
cp SRC/*.h "$prefix/include"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuperlumts", :libsuperlumts),
    LibraryProduct("libsuperlumtd", :libsuperlumtd),
    LibraryProduct("libsuperlumtc", :libsuperlumtc),
    LibraryProduct("libsuperlumtz", :libsuperlumtz),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
