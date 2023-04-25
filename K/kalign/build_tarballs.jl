using BinaryBuilder, Pkg

name = "kalign"
version = v"3.3.5"
# url = "https://github.com/TimoLassmann/kalign"
# description = "A fast multiple sequence alignment program."

# NOTES
# - fails to build on windows
#   - undefined references to localtime_r
#   - warning: implicit definition of getline

sources = [
    GitSource("https://github.com/TimoLassmann/kalign",
              "58ca06a51b53d76d3fb96ef335fbc7110c36cd46"),
]

script = raw"""
cd $WORKSPACE/srcdir/kalign*/
mkdir build && cd build

# avoid autodetection (because we are cross-compiling)
if [[ "${target}" == x86_64-* || "${target}" == i686-* ]]; then
    CMAKE_EXTRA_FLAGS="-DENABLE_SSE=ON -DENABLE_AVX=ON -DENABLE_AVX2=ON"
else
    CMAKE_EXTRA_FLAGS="-DENABLE_SSE=OFF -DENABLE_AVX=OFF -DENABLE_AVX2=OFF"
fi

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DUSE_OPENMP=ON \
    ${CMAKE_EXTRA_FLAGS}
make -j${nproc}
make install
install_license ../COPYING
"""

platforms = supported_platforms(; exclude = p -> Sys.iswindows(p))
platforms = expand_cxxstring_abis(platforms; skip = p -> Sys.isfreebsd(p) || (Sys.isapple(p) && arch(p) == "aarch64"))

products = [
    ExecutableProduct("kalign", :kalign),
    LibraryProduct("libkalign", :libkalign),
]

dependencies = Dependency[
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else, however
    # other libraries from `CompilerSupportLibraries_jll` are needed on x86_64 macOS and
    # FreeBSD
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"7")
