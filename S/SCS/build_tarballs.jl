using Pkg
using BinaryBuilder

name = "SCS"
version = v"3.2.6"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "2b9b03d1b312da8e5db49e664b4998123c8ad6bb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scs*
flags="DLONG=1 USE_OPENMP=1"
blasldflags="-L${prefix}/lib -lopenblas"

make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsdir.${dlext}
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsindir.${dlext}

mkdir -p ${libdir}
cp out/libscs*.${dlext} ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscsindir", :libscsindir),
    LibraryProduct("libscsdir", :libscsdir)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll", v"0.3.10"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
        platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
        platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
