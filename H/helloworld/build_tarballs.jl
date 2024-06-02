# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "helloworld"
version = v"0.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mankai-chow/test_bin_2.git", "340118b48dbc53032b082474076eafdc373c432c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd test_bin_2
export MKL_THREADING_LAYER=GNU
gfortran -fPIC -larpack -fopenmp -O3 -c ./cfs.f90
gfortran -fPIC -larpack -fopenmp -O3 -c ./bs.f90
gfortran -fPIC -larpack -fopenmp -O3 -c ./op.f90
gfortran -fPIC -larpack -fopenmp -O3 -c ./diag.f90
gfortran -fPIC -larpack -fopenmp -O3 -c ./diag_re.f90
gfortran -fPIC -shared -larpack -fopenmp -O3 -o $prefix/lib.so ./*.o -L /workspace/*/destdir/bin
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("lib", :LibPath)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"))
    Dependency(PackageSpec(name="Arpack_jll", uuid="68821587-b530-5797-8361-c406ea357684"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
