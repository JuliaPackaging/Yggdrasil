using Pkg
using BinaryBuilder

name = "SCS_MKL"
version = v"3.2.7"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "775a04634e40177573871c9cb6baae254342de39")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scs*
scsflags="DLONG=1 USE_OPENMP=1 BLAS32=1 NOBLASSUFFIX=1"
mklflags="-L${prefix}/lib -Wl,--no-as-needed -lmkl_rt -lmkl_core -lpthread -lm -ldl"

make ${scsflags} MKLFLAGS="${mklflags}" out/libscsmkl.${dlext}

mkdir -p ${libdir}
cp out/libscs*.${dlext} ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    # Platform("i686", "linux"; libc="glibc"),
    # Platform("x86_64", "macos"),
    # Platform("i686", "windows"),
    # Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libscsmkl", :libscsmkl, dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MKL_jll"; compat = "=2023.2.0"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
        platforms=filter(!Sys.isbsd, platforms)),
    # Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
    #     platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
