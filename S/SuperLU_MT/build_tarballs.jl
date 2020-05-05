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

atomic_patch -p1 ../patches/01-fix-makefiles.patch

# Build object files suitable for a shared library, and link the libraries we need.
echo "CFLAGS += -fPIC -fopenmp \$(BLASLIB)" >> make.inc
echo "NOOPTS += -fPIC -fopenmp \$(BLASLIB)" >> make.inc

# If our OpenBLAS is 64-bit, we need to suffix some symbols.
if [[ "$nbits" == 64 && "$target" != aarch64-* ]]; then
  BLAS_SUFFIX=64_
  SYMBOLS=()
  for sym in dasum daxpy dcopy dtrsv idamax; do
    SYMBOLS+=("-D$sym=${sym}_64_")
  done
  echo "CFLAGS += ${SYMBOLS[@]}" >> make.inc
fi

# We're building a shared library, not a static one.
sed -i "s/SUPERLULIB.*/SUPERLULIB = libsuperlu_mt\$(PLAT).$dlext/" make.inc

# Don't use 64-bit integers on non-64-bit systems.
if [[ "$nbits" != 64 ]]; then
  sed -i "s/^CFLAGS.*+= -D_LONGINT$//" make.inc
fi

# Clang doesn't play nicely with OpenMP.
if [[ "$target" == *-freebsd* || "$target" == *-apple-* ]]; then
  CC=gcc
fi

# Weird sed delimiters because some variables contain slashes.
sed -i "s~^BLASLIB.*~BLASLIB = -L$libdir -lopenblas$BLAS_SUFFIX~" make.inc
sed -i "s~^CC.*~CC = $CC~" make.inc
sed -i "s~^FORTRAN.*~FORTRAN = $FC~" make.inc

make superlulib "-j$nproc"
cp "lib/libsuperlu_mt_OPENMP.$dlext" "$libdir"
cp SRC/*.h "$prefix/include"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuperlu_mt_OPENMP", :libsuperlu_mt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
