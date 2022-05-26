using BinaryBuilder

name = "libopencc"
version = v"1.1.3"
sources = [
  ArchiveSource("https://github.com/BYVoid/OpenCC/archive/refs/tags/ver.1.1.3.tar.gz", "99a9af883b304f11f3b0f6df30d9fb4161f15b848803f9ff9c65a96d59ce877f")
]

script = raw"""
cd ${WORKSPACE}/srcdir/OpenCC-ver.1.1.3
cmake -S. -Bbuild -DCMAKE_INSTALL_PREFIX:PATH=${prefix}
cmake --build build --config Release --target install
"""

platforms = [
  Platform("x86_64", "linux"),
]

products = [
  LibraryProduct("libopencc", :libopencc),
  FileProduct("share/opencc/TSCharacters.ocd2", :opencc_char),
  FileProduct("share/opencc/TSPhrases.ocd2", :opencc_phra),
  FileProduct("share/opencc/t2s.json", :opencc_conf)
]

dependcies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependcies, preferred_gcc_version = v"11.1.0")
