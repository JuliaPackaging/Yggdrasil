# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LFortran"
version = v"0.18.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://lfortran.github.io/tarballs/release/lfortran-$(version).tar.gz",
                  "f796b242072d92fae36bcff2e6fddd649e89dccf877feaf99ecfab552e7e1e29")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lfortran-*
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DWITH_LLVM=yes -DCMAKE_C_FLAGS_RELEASE="-std=gnu99 -O3 -DNDEBUG" -DCMAKE_CXX_FLAGS_RELEASE="-Wall -Wextra -O3 -funroll-loops -pthread -D__STDC_FORMAT_MACROS -DNDEBUG" .
make -j$nproc
make install
install_license LICENSE 
cp src/bin/cpptranslate $bindir/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc", cxxstring_abi = "cxx11")
    Platform("x86_64", "linux"; libc = "musl", cxxstring_abi = "cxx11")
]

# The products that we will ensure are always built
products = [
    LibraryProduct("liblfortran_runtime", :liblfortran_runtime, "share/lfortran/lib"),
    ExecutableProduct("lfortran", :lfortran),
    ExecutableProduct("cpptranslate", :cpptranslate)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"); compat="~2.13.6")
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8", preferred_llvm_version = v"11")
