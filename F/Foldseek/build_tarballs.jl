# TODO
# - use Zstd_jll ? (static lib?) (now uses builtin zstd lib)

# Build fails
# - x86_64-freebsd
#   compilation error, seems like a clash between KASSERT macro defined in lib/kerasify/keras_model.h
#   and usage in freebsd headers, e.g. at line 190 of
#   /opt/x86_64-unknown-freebsd12.2/x86_64-unknown-freebsd12.2/sys-root//usr/include/sys/time.h
#   see: https://github.com/JuliaPackaging/Yggdrasil/pull/6195#issuecomment-1416227398

using BinaryBuilder, Pkg

name = "Foldseek"

# foldseek seem to use as versioning scheme of "major version + first 7
# characters of the tagged commit"
version = v"5"
# version_commitprefix = "53465f0"

# url = "https://github.com/steineggerlab/foldseek"
# description = "Fast and sensitive comparisons of large protein structure sets"

sources = [
    # Foldseek 5-53465f0
    # Note: this is the same commit as v"4" in Yggdrasil
    GitSource("https://github.com/steineggerlab/foldseek",
              "53465f07cdeed1f7fda08ee7f188327cb57c37ba"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/foldseek*/

# patch lib/mmseqs/CMakeLists.txt so it doesn't set -march unnecessarily on ARM
atomic_patch -p1 ../patches/mmseqs-arm-simd-march-cmakefile.patch

ARCH_FLAGS=
if [[ "${target}" == x86_64-* || "${target}" == i686-* ]]; then
    ARCH_FLAGS="-DHAVE_SSE2=1 -DHAVE_SSE4_1=1 -DHAVE_AVX2=1"
elif [[ "${target}" == powerpc64le-* ]]; then
    ARCH_FLAGS="-DHAVE_POWER8=1 -DHAVE_POWER9=1"
elif [[ "${target}" == aarch64-* ]]; then
    ARCH_FLAGS="-DHAVE_ARM8=1"
fi

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=RELEASE \
    -DNATIVE_ARCH=0 ${ARCH_FLAGS}
make -j${nproc}
make install

install_license ../LICENSE.md
"""

platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || Sys.isfreebsd(p) || arch(p) == "i686")
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("foldseek", :foldseek)
]

dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="Bzip2_jll")),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"8")
