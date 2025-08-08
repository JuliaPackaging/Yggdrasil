using BinaryBuilder

name = "odrpack"
version = v"2.0.1"

sources = [
    GitSource("https://github.com/HugoMVale/odrpack95.git", "54e58ae7f56564e358fb097f2108e4112498fce9")
]

platforms = [
    Platform("i686",    "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64",  "linux"; libc="glibc"),
    Platform("i686",    "windows"),
    Platform("x86_64",  "windows"),
    Platform("x86_64",  "macos"),
    Platform("x86_64",  "freebsd")
]

# platforms = expand_gfortran_versions(platforms)
# Disable old libgfortran builds - only use libgfortran5
# filter!(p -> !(any(libgfortran_version(p) .== (v"4.0.0", v"3.0.0"))), platforms)

products = [
    LibraryProduct("libodrpack95", :libodrpack95)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll")
]

script = raw"""
cd $WORKSPACE/srcdir/odrpack95

mkdir build && cd build
meson setup .. --cross-file="${MESON_TARGET_TOOLCHAIN}" -Dbuild_shared=true
ninja -j${nproc}
ninja install
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"14")
