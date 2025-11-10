# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "slow5lib"
version = v"1.3.1"

sources = [
    GitSource("https://github.com/hasindu2008/slow5lib.git", "050c09868696d98735152bf0abb3de766f5ab5cb"),
    DirectorySource("./patches")
]

script = raw"""
if [[ "${target}" == *-apple-darwin* ]]; then
    actual_lib_dir="${WORKSPACE}/$(readlink ${WORKSPACE}/destdir)/lib"
    export LDFLAGS="-L${actual_lib_dir} -lz"
fi
cd $WORKSPACE/srcdir/slow5lib
atomic_patch -p1 ../fix_cmakelists_for_slow5lib.patch
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
install -Dvm 755 $WORKSPACE/srcdir/slow5lib/build/libslow5.${dlext} ${libdir}/libslow5.${dlext}
cp -r $WORKSPACE/srcdir/slow5lib/include/slow5 $WORKSPACE/destdir/include
install_license ${WORKSPACE}/srcdir/slow5lib/LICENSE
"""

platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)
filter!(p -> arch(p) != "riscv64", platforms)


products = [
    LibraryProduct("libslow5", :libslow5)
]

dependencies = Dependency[
    Dependency("Zlib_jll", v"1.2.12")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
