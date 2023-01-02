# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Perple_X"
version = v"7.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jadconnolly/Perple_X.git", "33565053cfaad60ec6d119a4cfdce1c38f87941f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Perple_X/sources/

FilesArray=("vertex"  "build"  "actcor"  "convex" "ctransf" "fluids" "frendly" "meemum" "pspts" "pssect" "pstable" "psvdraw" "pt2curv" "werami")

# 1) compile binaries
make -j${nproc} -f makefile_691 EXT=${exeext}

# deploy binaries & libraries
for file in ${FilesArray[*]}; do
    install -Dvm 755 $file${exeext} "${bindir}/$file${exeext}"
done;

# 2) compile shared libraries
make -f makefile_691 clean
make -j${nproc} -f makefile_691 EXT=.${dlext} FLINK='-shared' FFLAGS='-fPIC -O3'

# deploy 
for file in ${FilesArray[*]}; do
    install -Dvm 755 $file.${dlext} "${libdir}/lib$file.${dlext}"
done;

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("fluids", :fluids),
    LibraryProduct("libfluids", :libfluids),
    
    ExecutableProduct("meemum", :meemum),
    LibraryProduct("libmeemum", :libmeemum),
    
    ExecutableProduct("pt2curv", :pt2curv),
    LibraryProduct("libpt2curv", :libpt2curv),
    
    ExecutableProduct("pspts", :pspts),
    LibraryProduct("libpspts", :libpspts),

    ExecutableProduct("actcor", :actcor),
    LibraryProduct("libactcor", :libactcor),
    
    ExecutableProduct("ctransf", :ctransf),
    LibraryProduct("libctransf", :libctransf),
    
    ExecutableProduct("frendly", :frendly),
    LibraryProduct("libfrendly", :libfrendly),
    
    ExecutableProduct("vertex", :vertex),
    LibraryProduct("libvertex", :libvertex),
    
    ExecutableProduct("build", :build),
    LibraryProduct("libbuild", :libbuild),
    
    ExecutableProduct("pstable", :pstable),
    LibraryProduct("libpstable", :libpstable),
    
    ExecutableProduct("psvdraw", :psvdraw),
    LibraryProduct("libpsvdraw", :libpsvdraw),
    
    ExecutableProduct("pssect", :pssect),
    LibraryProduct("libpssect", :libpssect),
    
    ExecutableProduct("werami", :werami),
    LibraryProduct("libwerami", :libwerami),
    
    ExecutableProduct("convex", :convex),
    LibraryProduct("libconvex", :libconvex)

]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
