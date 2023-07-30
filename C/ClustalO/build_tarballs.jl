# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ClustalO"
version = v"1.2.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/GSLBiotech/clustal-omega.git",
                  "d21fab82d380638c568c9427ed39cb42dd87d93b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/clustal-omega
install_license LICENSE COPYING
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DARGTABLE_INCLUDE_DIR=${includedir} -DARGTABLE_LIBRARY_DIR=${libdir} \
-DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
	ExecutableProduct("clustalo", :clustalo)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(; name="argtable_jll", uuid="166911fe-1485-5b25-83ac-750489179000"); compat="2.13", platforms=platforms),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(; name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(; name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")

