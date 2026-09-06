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

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/openmp-find-package.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmaple-openmp-find-package.patch
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

# `#include <Windows.h>` (capital W) is fine on case-insensitive Windows
# but breaks on the case-sensitive BB Linux sandbox cross-compiling mingw.
sed -i 's|#include <Windows\.h>|#include <windows.h>|g' utils/timeutil.h

mkdir -p build && cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DEIGEN3_INCLUDE_DIR=${includedir}/eigen3

make -j${nproc}
make install

# Drop the Windows GUI-launcher variant. Julia consumers call iqtree3()
# directly; the click variant is dead weight in a JLL.
rm -f ${bindir}/iqtree3-click.exe

install_license ${WORKSPACE}/srcdir/iqtree3/LICENSE
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

# For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
# systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70")),
    Dependency("boost_jll"; compat="1.87"),
    Dependency("Zlib_jll"; compat="1.2.13"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               compat="1.0.5", platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
