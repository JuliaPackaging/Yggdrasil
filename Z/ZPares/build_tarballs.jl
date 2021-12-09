# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZPares"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cometscome/zpares_mirror.git", "1e84be7cd0f8368da09ac0c262f815583ce04b7d")
    FileSource("https://zpares.cs.tsukuba.ac.jp/?download=242","3c34257d249451b0b984abc985e296ebb73ae5331025f1b8ea08d50301c7cf9a",filename="zpares_0.9.6a.tar.gz")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
tar -xvf zpares_0.9.6a.tar.gz 
cd zpares_mirror/
install_license ./LICENSE
cd ../zpares_0.9.6a
cp ../zpares_mirror/wrapper/zpares_wrapper.f90 ./

if [[ $target == *"aarch64-apple-darwin"* ]]; then 
    Rankmismatch="-fallow-argument-mismatch"
fi

cp Makefile.inc/make.inc.gfortran.seq ./make.inc
make BLAS="-L${libdir} -lopenblas" USE_MPI="0" FFLAG="-O3 ${Rankmismatch} -shared -fPIC -L${libdir} -lopenblas" LAPACK="-L./"
gfortran -O3 -shared -fPIC zpares_wrapper.f90 -I./include -L./lib -lzpares -L${libdir} -lopenblas -o "${libdir}/libzpares.${dlext}"
cp include/zpares.mod "${includedir}"
cp zpares_wrapper.mod "${includedir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)
platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libzpares", :libzpares),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
