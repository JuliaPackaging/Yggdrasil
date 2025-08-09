using BinaryBuilder

name = "odrpack"
version = v"2.0.1"

sources = [
    GitSource("https://github.com/HugoMVale/odrpack95.git", "ca803f43108eedf6bc3581023327f3e4d8d30767")
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

# script = raw"""
# cd $WORKSPACE/srcdir/odrpack95

# mkdir build && cd build
# meson setup .. --cross-file="${MESON_TARGET_TOOLCHAIN}" -Dbuild_shared=true
# ninja -j${nproc}
# ninja install
# """

script = raw"""
cd $WORKSPACE/srcdir/odrpack95
mkdir build && cd build
cmake ..\
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_SHARED=ON
make --build . --parallel ${nproc}
cmake --install .
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"14")
