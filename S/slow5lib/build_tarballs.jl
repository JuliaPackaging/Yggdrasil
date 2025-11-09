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
else
    export LDFLAGS="-L${libdir}"
fi
cd $WORKSPACE/srcdir
atomic_patch -p1 fix_cmakelists_for_slow5lib.patch
cd slow5lib/
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
cp $WORKSPACE/srcdir/slow5lib/build/libslow5.${dlext} $WORKSPACE/destdir/lib
cp -r $WORKSPACE/srcdir/slow5lib/include/slow5 $WORKSPACE/destdir/include
install_license ${WORKSPACE}/srcdir/slow5lib/LICENSE
"""

platforms = filter(plt -> plt.tags["os"] != "windows" && plt.tags["arch"] != "riscv64",
                   supported_platforms())


products = [
    LibraryProduct("libslow5", :libslow5)
]

dependencies = Dependency[
    Dependency("Zlib_jll", v"1.2.12")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
