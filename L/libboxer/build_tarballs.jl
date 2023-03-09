# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libboxer"
version = v"0.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/feenkcom/libboxer.git", "0f5344e155c932d8ab625cdd6b0296382bf2564d"),
    FileSource("https://github.com/feenkcom/libboxer/releases/download/v$(version)/boxer.h", 
               "0d9cbd8e8c3cc0f0679d88d5ae17790d7b4dc8c70ab45e6959e031a5ec863072"),
]

# Adapted from the justfile of the repo
script = raw"""
install -Dvm 0755 "boxer.h" "${includedir}/boxer.h"
cd $WORKSPACE/srcdir/libboxer
cargo build --release
install_license LICENSE
if [[ "${target}" == *-mingw* ]]; then
    install -Dvm 0755 "target/${rust_target}/release/Boxer.${dlext}" "${libdir}/libBoxer.${dlext}"
else
    install -Dvm 0755 "target/${rust_target}/release/libBoxer.${dlext}" "${libdir}/libBoxer.${dlext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> (Sys.iswindows(p) && arch(p) == "i686") || (Sys.islinux(p) && libc(p) == "musl") || Sys.isbsd(p))

# The products that we will ensure are always built
products = [
    LibraryProduct("libBoxer", :libBoxer),
    FileProduct("include/boxer.h", :boxer_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])
