using BinaryBuilder

name = "libcbor"
version = v"0.12.0"

sources = [
    GitSource("https://github.com/PJK/libcbor.git",
              "ae000f44e8d2a69e1f72a738f7c0b6b4b7cc4fbf")
]

script = raw"""
cd ${WORKSPACE}/srcdir/libcbor*
options=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_PREFIX_PATH=${prefix}
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_INSTALL_LIBDIR=${libdir}
    -DCMAKE_INSTALL_INCLUDEDIR=${includedir}
    -DBUILD_SHARED_LIBS=ON
    -DWITH_EXAMPLES=OFF
)

# Disable LTO on macOS. It gives an error about trying to use an LLVM 18 file with an LLVM 8 linker:
# 'Invalid value (Producer: 'LLVM18.1.7' Reader: 'LLVM 8.0.0svn')', using libLTO version 'LLVM version 8.0.0svn' file 'CMakeFiles/cbor.dir/cbor.c.o'
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    options+=(-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF)
fi

mkdir build
cd build
cmake -S .. -B . ${options[@]}

make -j${nproc}
make -j${nproc} install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libcbor", :libcbor)
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
