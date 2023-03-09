# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libwinit"
version = v"0.32.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/feenkcom/libwinit.git", "43b2401d62cf61a2031e3c2cccdb6edef22a06ef"),
    FileSource("https://github.com/feenkcom/libwinit/releases/download/v$(version)/winit.h", 
               "d16e3fef287637bb2f29d8f1b6f715052cdf43bea4177afc412c6571f9638821"),
]

# Adapted from the justfile of the repo
script = raw"""
install -Dvm 0644 "winit.h" "${includedir}/winit.h"
cd $WORKSPACE/srcdir/libwinit
cargo build --release
install_license LICENSE
if [[ "${target}" == *-mingw* ]]; then
    install -Dvm 0755 "target/${rust_target}/release/Winit.${dlext}" "${libdir}/libWinit.${dlext}"
else
    install -Dvm 0755 "target/${rust_target}/release/libWinit.${dlext}" "${libdir}/libWinit.${dlext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> nbits(p) == 32 || libc(p) == "musl" || Sys.isbsd(p))

# The products that we will ensure are always built
products = [
    LibraryProduct("libWinit", :libWinit),
    FileProduct("include/winit.h", :winit_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libboxer_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])
