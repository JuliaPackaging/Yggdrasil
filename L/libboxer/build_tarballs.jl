
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libboxer"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/feenkcom/libboxer/archive/refs/tags/v$(version).tar.gz",
                  "57d25e5339b0c7b1d8c8242484ce2c4baca05fbea035c8e2d8aab05573eed0c9"),
    FileSource("https://github.com/feenkcom/libboxer/releases/download/v$(version)/boxer.h", 
               "f7e679d2faddca7a99399a03a1fa21c49c0780cf2b73be2c4dd2f70d7a963637"),
]

# Adapted from the justfile of the repo
script = raw"""
install -Dvm 0755 "boxer.h" "${includedir}/boxer.h"
cd $WORKSPACE/srcdir/libboxer-*
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
