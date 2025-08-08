using BinaryBuilder

name = "odrpack95"
version = v"2.0.1"

# Collection of sources required to build ECOSBuilder
sources = [
    GitSource("https://github.com/HugoMVale/odrpack95.git", "54e58ae7f56564e358fb097f2108e4112498fce9")
]

platforms = [
    # Platform("x86_64", "windows")
    Platform("x86_64", "linux"; libc="glibc")
]

products = [
    LibraryProduct("libodrpack95", :libodrpack95)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll")
]

script = raw"""
cd $WORKSPACE/srcdir/odrpack95

# Set pkg-config path so Meson can find openblas.pc
export PKG_CONFIG_PATH="${prefix}/lib/pkgconfig"

# Optional: show what pkg-config sees
pkg-config --list-all | grep blas || true

# Configure Meson, build and install
mkdir build && cd build
meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}" -Dbuild_shared=true
ninja -j${nproc}
ninja install
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"14")
