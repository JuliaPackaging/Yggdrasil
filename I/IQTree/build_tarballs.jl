# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "IQTree"
version = v"3.1.2"

# Submodules pinned to their SHAs at v3.1.2; relocated in the script.
sources = [
    GitSource("https://github.com/iqtree/iqtree3.git",
              "4e91dd61447c301a896014002b3509bec05f8ab1"),  # v3.1.2
    GitSource("https://github.com/tothuhien/lsd2.git",
              "c61110f3a4fa05325b45c97b2134792ff9d55d4c"),
    GitSource("https://github.com/trongnhanuit/cmaple.git",
              "3d45b1ab68e2d68a2825bf17a531e22200578cd6"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/iqtree3

rm -rf lsd2 cmaple
mv ../lsd2 lsd2
mv ../cmaple cmaple

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/openmp-find-package-on-linux.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/respect-cross-compile-osx-arch.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmaple-disable-lto.patch

# AppleDouble sidecars in the rootfs break CMake compiler detection
# (BB-on-darwin hosts only).
find /usr/share/cmake -name '._*' -delete || true

# BB rejects forced -march/-mcpu; iqtree3 hardcodes them in three
# CMakeLists. Stop class avoids eating the closing `)`.
find . -name CMakeLists.txt -exec sed -i 's/-march[^ "()]*//g; s/-mcpu[^ "()]*//g' {} +

# iqtree3's Windows post-build steps use the shell `copy` command,
# which isn't available in BB's mingw cross-compile sandbox.
sed -i 's/COMMAND copy /COMMAND ${CMAKE_COMMAND} -E copy /g' CMakeLists.txt

mkdir -p build && cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DEIGEN3_INCLUDE_DIR=${includedir}/eigen3

make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/iqtree3/LICENSE
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    ExecutableProduct("iqtree3", :iqtree3),
]

# libgomp on Linux, libomp on macOS/FreeBSD.
dependencies = [
    BuildDependency("Eigen_jll"),
    Dependency("boost_jll"; compat="=1.87.0"),
    Dependency("Zlib_jll"; compat="1.3.1"),
    Dependency("CompilerSupportLibraries_jll";
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll";
               platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
