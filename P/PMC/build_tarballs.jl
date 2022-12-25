using BinaryBuilder

name = "PMC"
version = v"0.1.1"
sources = [
           GitSource("https://github.com/dev10110/pmc","55b617c336a48f84657ebaafefe7f495b8b31a7d") 
]

script = raw"""
cd ${WORKSPACE}/srcdir/pmc
rm -rf build
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libpmc", :libpmc),
]

dependencies = Dependency[
]

julia_compat = "1.6"

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat=julia_compat)
