# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "IQTree"
version = v"3.1.4"

# lsd2 and cmaple are submodules, at the commits the release pins
sources = [
    GitSource("https://github.com/iqtree/iqtree3.git",
              "63c330d90dd02241dbbbaf1e9f9e9cc6dadbd1de"; tag="v$(version)"),
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

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/openmp-find-package.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmaple-openmp-find-package.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/respect-cross-compile-osx-arch.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmaple-disable-lto.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-cross-compile.patch

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

# A copy of iqtree3.exe for double-clicking in Explorer
if [[ ${target} == *mingw* ]]; then
    rm -v ${bindir}/iqtree3-click.exe
fi

install_license LICENSE vectorclass/license.txt
for dir in cmaple lsd2 terraphast yaml-cpp; do
    install -Dvm 644 ${dir}/LICENSE ${prefix}/share/licenses/${SRC_NAME}/LICENSE-${dir}
done
"""

# Upstream iqtree3 errors on 32-bit (CMakeLists.txt:480, "32-bit
# compilation is not supported") and hardcodes -msse3/-mavx/-mfma on any
# non-ARM target (CMakeLists.txt:670/687/710) - so ppc64le and riscv64
# fail in the vectorclass and PLL submodules.
platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms)
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)
# Zlib_jll stdlib on Julia 1.10-1.12 (1.2.13+1, 1.3.1+0) has no aarch64-freebsd binary.
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("iqtree3", :iqtree3),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    # Only Boost's headers are used
    BuildDependency("boost_jll"),
    Dependency("Zlib_jll"; compat="1.2.13"),
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5", platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll"; compat="18.1.8", platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
