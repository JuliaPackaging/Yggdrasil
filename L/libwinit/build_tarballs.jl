# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libwinit"
version = v"0.17.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/feenkcom/libwinit/archive/refs/tags/v$(version).tar.gz",
                  "dab68ccefaf496d5c3de751a15a0be54a3eb1ee2d4260105ec3343875c54f0e3"),
    FileSource("https://github.com/feenkcom/libwinit/releases/download/v$(version)/winit.h", 
               "d35910a1c54cf093f70e0cafddb72442f453635cc8147f1c61cb9d9b794da313"),
]

# Adapted from the justfile of the repo
script = raw"""
install -Dvm 0755 "winit.h" "${includedir}/winit.h"
cd $WORKSPACE/srcdir/libwinit-*
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
platforms = supported_platforms(; exclude=p -> (Sys.iswindows(p) && arch(p) == "i686") || (Sys.islinux(p) && (libc(p) == "musl" || arch(p) == "armv6l")) || Sys.isbsd(p))

# The products that we will ensure are always built
products = [
    LibraryProduct("libWinit", :libWinit),
    FileProduct("include/winit.h", :winit_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("libboxer_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])
