# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "finufft"
version = v"2.0.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/flatironinstitute/finufft/archive/v$(version).zip", "fe83dbc22a1d13799e9db48568d8417d3028e7b831800f2a626ea19b4f0461fe")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/finufft*/
# Overwrite LIBSFFT such that we do not require fftw3_threads or fftw3_omp for OMP support. Since the libraries in FFTW_jll already provide for threading, we do not loose anything.
# Make use of the -DFFTW_PLAN_SAFE flag to allow for multiple threads using finufft at the same time.
make lib CFLAGS="-fPIC -O3 -funroll-loops -fcx-limited-range -Iinclude" CXXFLAGS="-fPIC -O3 -funroll-loops -fcx-limited-range -Iinclude -std=c++14 -DFFTW_PLAN_SAFE" LIBSFFT="-lfftw3 -lfftw3f -lm"
mv lib/libfinufft.so "${libdir}/libfinufft.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libfinufft", :libfinufft)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9")
