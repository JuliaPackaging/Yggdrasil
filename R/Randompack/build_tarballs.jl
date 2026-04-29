using BinaryBuilder, Pkg

name = "Randompack"
version = v"0.1.5"

sources = [
  GitSource(
    "https://github.com/jonasson2/randompack.git",
    "4f91c55f93b027c72bc46971bf7c3df3a4960145",
  ),
]

script = raw"""
set -e
# Work around stray AppleDouble files that can break Python site.py decoding.
find /usr/lib/python3.9/site-packages -maxdepth 1 -name '._*' -delete 2>/dev/null || true

cd $WORKSPACE/srcdir
SRC=$WORKSPACE/srcdir/randompack

manual_apple_build_backup() {
  # Backup of the previous manual macOS build path. Keep this until the Meson
  # macOS/aarch64 BinaryBuilder build has been verified.
  BUILD=$WORKSPACE/build-manual
  rm -rf $BUILD
  mkdir -p $BUILD $prefix/lib $prefix/include $prefix/share/licenses/Randompack

  CDEFS="-D_POSIX_C_SOURCE=200809L -D_DARWIN_C_SOURCE -DLOCAL_DPSTRF -DUSE_ACCEL_VV"
  COPTS="-O3 -fPIC -fno-math-errno -fno-trapping-math -fomit-frame-pointer"
  COPTS="$COPTS -fno-semantic-interposition"
  if echo "$target" | grep -q '^aarch64-apple-darwin'; then
    COPTS="$COPTS -mcpu=apple-m1"
  fi

  $CC -std=c11 $COPTS $CDEFS -I$SRC/src -c $SRC/src/printX.c -o $BUILD/printX.c.o
  $CC -std=c11 $COPTS $CDEFS -I$SRC/src -c $SRC/src/rp_dpstrf.c -o $BUILD/rp_dpstrf.c.o
  $CC -std=c11 $COPTS $CDEFS -I$SRC/src -c $SRC/src/randompack.c -o $BUILD/randompack.c.o

  $CC -shared -o $prefix/lib/librandompack.dylib \
    $BUILD/randompack.c.o $BUILD/printX.c.o $BUILD/rp_dpstrf.c.o \
    -framework Accelerate -lm \
    -Wl,-install_name,@rpath/librandompack.dylib

  cp $SRC/src/randompack.h $prefix/include/
  cp $SRC/src/randompack_config.h $prefix/include/
  cp $SRC/LICENSE $prefix/share/licenses/Randompack/LICENSE
}

cd $WORKSPACE
rm -rf build

P1="${prefix}/lib/pkgconfig:${prefix}/lib64/pkgconfig:${prefix}/share/pkgconfig"
export PKG_CONFIG_PATH="$P1:${PKG_CONFIG_PATH:-}"
export CPPFLAGS="-I${prefix}/include ${CPPFLAGS:-}"
export LDFLAGS="-L${prefix}/lib -L${prefix}/lib64 ${LDFLAGS:-}"

EXTRA_MESON_FLAGS=""
if [[ "${target}" == x86_64-w64-mingw32 ]]; then
  EXTRA_MESON_FLAGS="-Dforce_nosimd=true"
fi

meson setup build $SRC \
  --cross-file=${MESON_TARGET_TOOLCHAIN} \
  --buildtype=release \
  --prefix=${prefix} \
  -Ddefault_library=shared \
  -Dblas=openblas \
  -Dbuild_examples=false \
  -Dbuild_tests=false \
  -Dbuild_fortran_interface=false \
  ${EXTRA_MESON_FLAGS}

ninja -C build
ninja -C build install
"""

# Randompack requires 64-bit platforms.
platforms = filter(p -> nbits(p) == 64, supported_platforms())

dependencies = [
  Dependency(PackageSpec(name="OpenBLAS32_jll",
                         uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("librandompack", :librandompack)
]
		
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", clang_use_lld=false, dont_dlopen=true,
               preferred_gcc_version=v"8")
