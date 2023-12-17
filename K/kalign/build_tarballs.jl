using BinaryBuilder, Pkg

name = "kalign"
version = v"3.4.0"
# url = "https://github.com/TimoLassmann/kalign"
# description = "A fast multiple sequence alignment program."

# NOTES
# - fails to build on windows
#   - undefined references to localtime_r
#   - warning: implicit definition of getline

sources = [
    GitSource("https://github.com/TimoLassmann/kalign",
              "19156c577e8f959e97b2ec909cfd663df1ca969e"),
]

script = raw"""
cd $WORKSPACE/srcdir/kalign*/
mkdir build && cd build

# avoid autodetection (because we are cross-compiling)
if [[ "${target}" == x86_64-* || "${target}" == i686-* ]]; then
    CMAKE_EXTRA_FLAGS="-DHAVE_SSE=ON -DHAVE_AVX=ON -DHAVE_AVX2=ON"
else
    CMAKE_EXTRA_FLAGS="-DHAVE_SSE=OFF -DHAVE_AVX=OFF -DHAVE_AVX2=OFF"
fi
echo "CMAKE_EXTRA_FLAGS=$CMAKE_EXTRA_FLAGS"

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

platforms = supported_platforms(; exclude = Sys.iswindows)

products = [
    ExecutableProduct("kalign", :kalign),
    LibraryProduct("libkalign", :libkalign),
]

dependencies = Dependency[
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"7")
