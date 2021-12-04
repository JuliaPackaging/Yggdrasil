# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase

name = "WhiteboxTools"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/jblindsay/whitebox-tools/archive/refs/tags/v$(version).tar.gz", "18705fc948bdb2f96cd816e5a72d36b9cc460aa8c910383d23fdbd61641aab60")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/whitebox-tools-*/

cargo build --release
mkdir /workspace/destdir/bin/
find target/${rust_target}/release/ -maxdepth 1 -type f -executable | xargs -I '{}' mv {} /workspace/destdir/bin/
install_license LICENSE.txt

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
filter!(p -> libc(p) != "musl" || proc_family(p) != "arm", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("quinn_flow_accumulation", :quinn_flow_accumulation),
    LibraryProduct("qin_flow_accumulation", :qin_flow_accumulation),
    LibraryProduct("raster_calculator", :raster_calculator),
    LibraryProduct("rho8_flow_accumulation", :rho8_flow_accumulation),
    LibraryProduct("edge_contamination", :edge_contamination),
    LibraryProduct("whitebox_tools", :whitebox_tools),
    LibraryProduct("split_vector_lines", :split_vector_lines),
    LibraryProduct("exposure_towards_wind_flux", :exposure_towards_wind_flux),
    LibraryProduct("conditional_evaluation", :conditional_evaluation)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], lock_microarchitecture = false)
