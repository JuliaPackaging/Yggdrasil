# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "raptor"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tbronzwaer/raptor.git", "6cf2a5903af340c3cbf07fc9e13d43364c3187b4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd raptor/
make CPU="1" CFLAGS="-fopenmp -std=c99 -I{includedir} -Wno-unused-result" LDFLAGS="-lm -lgsl -lgslcblas"
cp RAPTOR *.o run.sh model.in dump040 ${prefix}/
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    FileProduct("integrator.o", :integrator),
    FileProduct("main.o", :main),
    FileProduct("rcarry.o", :rcarry),
    FileProduct("metric.o", :metric),
    FileProduct("GRmath.o", :GRmath),
    FileProduct("grmhd.o", :grmhd),
    FileProduct("j_nu.o", :j_nu),
    FileProduct("utilities.o", :utilities),
    ExecutableProduct("RAPTOR", :RAPTOR),
    FileProduct("radiative_transfer.o", :radiative_transfer),
    FileProduct("raptor_harm_model.o", :raptor_harm_model),
    FileProduct("newtonraphson.o", :newtonraphson),
    FileProduct("core.o", :core)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
