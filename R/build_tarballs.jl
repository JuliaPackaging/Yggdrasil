using BinaryBuilder

name = "Raylib"
version = v"3.7.0"
sources = [
  ArchiveSource("https://github.com/raysan5/raylib/archive/refs/tags/3.7.0.tar.gz",
                "7bfdf2e22f067f16dec62b9d1530186ddba63ec49dbd0ae6a8461b0367c23951"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/raylib-3.7.0
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
  LibraryProduct("libraylib", :libraylib),
]

dependencies = [
  BuildDependency("Xorg_xorgproto_jll"),
  Dependency("Libglvnd_jll"),
  Dependency("Xorg_libXrandr_jll"),
  Dependency("Xorg_libX11_jll"),
  Dependency("Xorg_libXrender_jll"),
  Dependency("Xorg_libXi_jll"),
  Dependency("Xorg_libXext_jll"),
  Dependency("Xorg_libXcursor_jll"),
  Dependency("Xorg_libXdamage_jll"),
  Dependency("Xorg_libXfixes_jll"),
  Dependency("Xorg_libXcomposite_jll"),
  Dependency("Xorg_libXinerama_jll"),
  Dependency("GLU_jll"),
  Dependency("Mesa_jll"),
  Dependency("alsa_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
