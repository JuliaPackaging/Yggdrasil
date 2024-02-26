using BinaryBuilder

name = "NanoVG"
version = v"1.0.0"

sources = [
   GitSource("https://github.com/memononen/nanovg", "7544c114e83db7cf67bd1c9e012349b70caacc2f"),
   DirectorySource("./bundled")
]

script = raw"""
cd $WORKSPACE/srcdir

mv cmake/CMakeLists.txt nanovg/

cd nanovg
atomic_patch -p1 ../patches/0001-fixed-missing-headers.patch

mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install

install_license ../LICENSE.txt
"""

platforms = supported_platforms()

filter!(p -> Sys.islinux(p) || Sys.iswindows(p), platforms)
filter!(p -> arch(p) != "armv6l", platforms)

products = [
   LibraryProduct("libnanovg", :libnanovg),
   LibraryProduct("libnanovggl2", :libnanovggl2),
   LibraryProduct("libnanovggl3", :libnanovggl3),
   LibraryProduct("libnanovggles2", :libnanovggles2),
   LibraryProduct("libnanovggles3", :libnanovggles3),
   FileProduct("share/compile_commands.json", :compile_commands),
]

dependencies = [
   Dependency("GLEW_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
