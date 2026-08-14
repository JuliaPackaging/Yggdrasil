# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LVGL_SDL"
version = v"9.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lvgl/lvgl.git", "4f086111a107718b719a45e2cc422f5b756d7edd"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lvgl
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/*.patch
if [[ "${target}" == "x86_64-apple-darwin14" ]]
then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/x86_64-apple-darwin14/*.patch
fi
cp lv_conf_template.h lv_conf.h
cp lv_conf.h ..

cmake -B build \
      -DBUILD_SHARED_LIBS=ON \
      -DLIB_INSTALL_DIR=${prefix}/lib \
      -DLV_CONF_BUILD_DISABLE_DEMOS=1 \
      -DLV_CONF_BUILD_DISABLE_EXAMPLES=1 \
      -DLV_CONF_INCLUDE_SIMPLE=OFF \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "linux"; libc="glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liblvgl", :liblvgl),
    LibraryProduct("liblvgl_thorvg", :liblvgl_thorvg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")
