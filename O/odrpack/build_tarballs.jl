using BinaryBuilder

name = "odrpack"
version = v"2.0.3"

sources = [
    GitSource("https://github.com/HugoMVale/odrpack95.git", 
    "6f5d1ff1541c29a6978eabaf60975ed5a8c68943") # tag=v2.0.3
]

platforms = supported_platforms()

platforms = filter(p -> !(libc(p) == "musl"), platforms)
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> libgfortran_version(p).major ≥ 5, platforms)

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
# gcc-14 fails with x86_64-apple
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false, preferred_gcc_version=v"13")
