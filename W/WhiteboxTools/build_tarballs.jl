# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase

name = "WhiteboxTools"
version = v"2.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jblindsay/whitebox-tools.git", "d4f252c84b37a6b70331c59fd930ffa9a574c5e1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/whitebox-tools/

cargo build --release
mkdir -p "${bindir}"
find target/${rust_target}/release/ -maxdepth 1 -type f -executable | xargs -I '{}' mv {} "${bindir}"
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("quinn_flow_accumulation", :quinn_flow_accumulation),
    ExecutableProduct("qin_flow_accumulation", :qin_flow_accumulation),
    ExecutableProduct("raster_calculator", :raster_calculator),
    ExecutableProduct("rho8_flow_accumulation", :rho8_flow_accumulation),
    ExecutableProduct("edge_contamination", :edge_contamination),
    ExecutableProduct("whitebox_tools", :whitebox_tools),
    ExecutableProduct("split_vector_lines", :split_vector_lines),
    ExecutableProduct("exposure_towards_wind_flux", :exposure_towards_wind_flux),
    ExecutableProduct("conditional_evaluation", :conditional_evaluation),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], lock_microarchitecture = false)
