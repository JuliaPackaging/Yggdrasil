using BinaryBuilder

name = "odrpack"
version = v"2.0.1"

sources = [
    GitSource("https://github.com/HugoMVale/odrpack95.git", "54e58ae7f56564e358fb097f2108e4112498fce9")
]

platforms = [
    # Platform("x86_64", "windows")
    Platform("x86_64", "linux"; libc="glibc")
]

filter!(p -> arch(p) != "riscv64", platforms)
platforms = expand_gfortran_versions(platforms)
# Disable old libgfortran builds - only use libgfortran5
filter!(p -> !(any(libgfortran_version(p) .== (v"4.0.0", v"3.0.0"))), platforms)

products = [
    LibraryProduct("libodrpack95", :libodrpack95)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll")
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
