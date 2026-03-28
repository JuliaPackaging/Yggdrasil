# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Randompack"
version = v"0.1.1"

sources = [
  ArchiveSource(
    "https://raw.githubusercontent.com/jonasson2/randompack-src/v0.1.1/randompack-0.1.1.tar.gz",
    "db3f048ddce772a77cacdf2d23a6bed58db4836b9d60f3dc6d1d910662926294",
  ),
]
    
script = raw"""
set -e
# Work around stray AppleDouble files that can break Python site.py decoding.
find /usr/lib/python3.9/site-packages -maxdepth 1 -name '._*' -delete \
  2>/dev/null || true

cd $WORKSPACE/srcdir
SRC=$WORKSPACE/srcdir/randompack-0.1.1
# Meson fails to detect the macOS/aarch64 linker in BinaryBuilder;
# build manually here.
if echo "$target" | grep -q 'apple-darwin'; then
  BUILD=$WORKSPACE/build-manual
  rm -rf $BUILD
  mkdir -p $BUILD $prefix/lib $prefix/include \
    $prefix/share/licenses/Randompack

  CDEFS="-D_POSIX_C_SOURCE=200809L -D_DARWIN_C_SOURCE -DLOCAL_DPSTRF -DUSE_ACCEL_VV"
  if echo "$target" | grep -q '^aarch64-apple-darwin'; then
    COPTS="-O3 -mcpu=apple-m1 -fPIC -fno-math-errno -fno-trapping-math -fomit-frame-pointer -fno-semantic-interposition"
  else
    COPTS="-O3 -fPIC -fno-math-errno -fno-trapping-math -fomit-frame-pointer -fno-semantic-interposition"
  fi

  AR=${target}-ar
  RANLIB=${target}-ranlib
  $FC -O3 -c $SRC/src/lapack_dpstrf.f -o $BUILD/lapack_dpstrf.f.o
  $CC -std=c11 $COPTS $CDEFS -I$SRC/src -c $SRC/src/printX.c \
    -o $BUILD/printX.c.o
  $CC -std=c11 $COPTS $CDEFS -I$SRC/src -c $SRC/src/randompack.c \
    -o $BUILD/randompack.c.o

  $CC -shared -o $prefix/lib/librandompack.dylib \
    $BUILD/randompack.c.o $BUILD/printX.c.o $BUILD/lapack_dpstrf.f.o \
    -framework Accelerate -lm -lgfortran \
    -Wl,-install_name,@rpath/librandompack.dylib

  $AR rcs $prefix/lib/librandompack.a \
    $BUILD/randompack.c.o $BUILD/printX.c.o $BUILD/lapack_dpstrf.f.o
  $RANLIB $prefix/lib/librandompack.a || true

  if [ -f $SRC/src/randompack.h ]; then
    cp $SRC/src/randompack.h $prefix/include/
  fi
  if [ -f $SRC/src/randompack_config.h ]; then
    cp $SRC/src/randompack_config.h $prefix/include/
  fi
  if [ -f $SRC/randompack.h ]; then
    cp $SRC/randompack.h $prefix/include/
  fi
  if [ -f $SRC/randompack_config.h ]; then
    cp $SRC/randompack_config.h $prefix/include/
  fi

  cp $SRC/LICENSE $prefix/share/licenses/Randompack/LICENSE
else
  cd $WORKSPACE
  rm -rf build

  export PKG_CONFIG_PATH="${prefix}/lib/pkgconfig:${prefix}/lib64/pkg<config:${prefix}/share/pkgconfig:${PKG_CONFIG_PATH:-}"
  export CPPFLAGS="-I${prefix}/include ${CPPFLAGS:-}"
  export LDFLAGS="-L${prefix}/lib -L${prefix}/lib64 ${LDFLAGS:-}"
    
  meson setup build $SRC \
    --cross-file=${MESON_TARGET_TOOLCHAIN} \
    --buildtype=release \
    --prefix=${prefix} \
    -Dblas=openblas \
    -Dbuild_examples=false \
    -Dbuild_tests=false \
    -Dbuild_fortran_interface=false
  ninja -C build
  ninja -C build install
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
  Platform("aarch64", "macos",   libgfortran_version="5.0.0"),
  Platform("x86_64",  "macos",   libgfortran_version="5.0.0"),
  Platform("x86_64",  "linux";   libgfortran_version="5.0.0", cxxstring_abi="cxx11"),
  Platform("aarch64", "linux";   libgfortran_version="5.0.0", cxxstring_abi="cxx11"),
  Platform("x86_64",  "windows"; libgfortran_version="5.0.0"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("librandompack", :librandompack)
]

dependencies = [
  Dependency(PackageSpec(name="CompilerSupportLibraries_jll",
                         uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
  Dependency(PackageSpec(name="OpenBLAS32_jll",
                         uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
]
		
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10")
