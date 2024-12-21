# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "rustfft"
version = v"0.4.0"
julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10", v"1.11"]

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Taaitaaiger/rustfft-jl.git",
              "52aba0563a07d02e3d142f81901853bbf5c0e8a1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/rustfft-jl

# This program prints the version feature that must be passed to `cargo build`
# Adapted from ../../G/GAP/build_tarballs.jl
# HACK: determine Julia version
cat > version.c <<EOF
#include <stdio.h>
#include "julia/julia_version.h"
int main(int argc, char**argv)
{
    printf("julia-%d-%d", JULIA_VERSION_MAJOR, JULIA_VERSION_MINOR);
    return 0;
}
EOF
${CC_BUILD} -I${includedir} -Wall version.c -o julia_version
julia_version=$(./julia_version)

cargo build --features yggdrasil,${julia_version} --release --verbose
install_license LICENSE
install -Dvm 0755 "target/${rust_target}/release/"*rustfft_jl".${dlext}" "${libdir}/librustfft.${dlext}"
"""

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)

# Successfully building for i686 Windows requires raw-dylib linkage, which is currently only
# supported for 64-bits Windows targets, or that libjulia.dll.a is available.
is_excluded(p) = Sys.iswindows(p) && nbits(p) == 32
filter!(!is_excluded, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("librustfft", :librustfft),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("Libiconv_jll"; platforms=filter(Sys.isapple, platforms)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6", compilers=[:c, :rust])
