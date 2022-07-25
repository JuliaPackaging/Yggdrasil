# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "spglib"
version = v"1.16.5"

# Collection of sources required to build spglib
sources = [
    ArchiveSource("https://github.com/atztogo/spglib/archive/v$(version).tar.gz",
                  "1bbde03b6b78da756c07f458bd90d84f3c253841b9b0632db5b72c5961e87aef"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/spglib-*/
if [[ ${target} == *-mingw32 ]]; then
    sed -i -e 's/LIBRARY/RUNTIME/' CMakeLists.txt
fi
mkdir _build
cd _build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
make -j${nproc}
make install VERBOSE=1
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsymspg", :libsymspg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
