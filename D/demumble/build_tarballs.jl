using BinaryBuilder, Pkg

name = "demumble"
version = v"1.3.0"

sources = [
    GitSource("https://github.com/nico/demumble",
              "e82c4520107ab87460c92a65d2b0e8b090b3f742"),
    DirectorySource("./bundled")
]

script = raw"""
cd $WORKSPACE/srcdir/demumble
install_license LICENSE

atomic_patch -p1 ../patches/0001-build-system-now-supports-more-build-environments.patch

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}

install -Dvm 755 "demumble${exeext}" "${bindir}/demumble${exeext}"
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    ExecutableProduct("demumble", :demumble)
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"10")
