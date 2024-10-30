# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Spasm"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/laurentbartholdi/spasm.git", "072719a40c837e447dfe4ae9e4941c60d9a28eda"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/spasm

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build

for t in bitmap check_cert dm echelonize kernel rank solve stack transpose vertical_swap; do
    cp build/tools/$t $prefix/bin/
done

cp build/src/libspasm* $prefix/lib/
cp src/spasm.h $prefix/include/

install_license ${WORKSPACE}/srcdir/spasm/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=Sys.iswindows) |> expand_cxxstring_abis
#platforms = supported_platforms(exclude=!Sys.isapple) |> expand_cxxstring_abis

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libspasm", :spasm),
    FileProduct("include/spasm.h", :spasm_h),
    ExecutableProduct("bitmap", :spasm_bitmap),
    ExecutableProduct("check_cert", :spasm_check_cert),
    ExecutableProduct("dm", :spasm_dm),
    ExecutableProduct("echelonize", :spasm_echelonize),
    ExecutableProduct("kernel", :spasm_kernel),
    ExecutableProduct("rank", :spasm_rank),
    ExecutableProduct("solve", :spasm_solve),
    ExecutableProduct("stack", :spasm_stack),
    ExecutableProduct("transpose", :spasm_transpose),
    ExecutableProduct("vertical_swap", :spasm_vertical_swap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Givaro_jll"; compat="4.2.0"),
    Dependency("FFLAS_FFPACK_jll"; compat="2.5.0"),
    Dependency("argp_standalone_jll"),
# strange warning: Dependency argp_standalone_jll does not have a mapping for artifact argp_standalone for platform x86_64-linux-gnu-libgfortran3-cxx11
    Dependency("libblastrampoline_jll"; compat="5.4.0"),
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("LLVMOpenMP_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  julia_compat="1.9", clang_use_lld=false, preferred_gcc_version=v"6")
