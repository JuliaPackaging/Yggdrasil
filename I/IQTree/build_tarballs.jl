# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "IQTree"
version = v"3.1.2"

# iqtree3 has lsd2 and cmaple as git submodules; GitSource doesn't recurse,
# so fetch each separately and move them into place in the script. SHAs
# match the submodule pins at the v3.1.2 tag.
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

# Cross-compile + portability patches. See bundled/patches/*.patch for the why.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/openmp-find-package-on-linux.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/respect-cross-compile-osx-arch.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmaple-disable-lto.patch

# Drop AppleDouble sidecars BB's tar unpack leaves in the rootfs on
# macOS hosts. CMake compiler detection trips on them.
find /usr/share/cmake -name '._*' -delete 2>/dev/null || true

# BB rejects forced -march/-mcpu; iqtree3 hardcodes them in three
# CMakeLists. Stop class avoids eating the closing `)`.
find . -name CMakeLists.txt -exec sed -i 's/-march[^ "()]*//g; s/-mcpu[^ "()]*//g' {} +

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

# Windows fails to link the kernelsse target (`undefined reference to
# GlobalMemoryStatusEx`) per the draft in Yggdrasil issue #7097, and
# iqtree3 auto-disables CMAPLE on mingw. Re-enable after upstream patches
# the link bug.
platforms = filter(!Sys.iswindows, supported_platforms())
platforms = expand_cxxstring_abis(platforms)

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

# iqtree3 sets GCC_MIN_VERSION=9 in CMakeLists; bump if a dep forces newer.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
