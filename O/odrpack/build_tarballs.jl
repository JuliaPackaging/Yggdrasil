using BinaryBuilder

name = "odrpack"
version = v"3.0.1"

sources = [
    GitSource("https://github.com/HugoMVale/odrpack95.git", 
    "22d3c785fee429febb9c1905ddfcca33a95cdc66") # tag=v3.0.1
]

platforms = supported_platforms()
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
               julia_compat="1.6", clang_use_lld=false, preferred_gcc_version=v"12")
