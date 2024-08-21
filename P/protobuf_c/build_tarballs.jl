# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "protobuf_c"
version = v"1.5.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/protobuf-c/protobuf-c/releases/download/v$(version)/protobuf-c-$(version).tar.gz",
                  "7b404c63361ed35b3667aec75cc37b54298d56dd2bcf369de3373212cc06fd98"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/protobuf-c*
# Small hack for x86_64-linux-musl-cxx03: swear that we are cross-compiling, which in a
# sense is true, since we can't run a C++ executable built for the target.  This avoids
# errors like
#     Error relocating ./protoc-c/protoc-gen-c: _ZN6google8protobuf8internal14ArenaStringPtr7MutableERKNS1_10LazyStringEPNS0_5ArenaE: symbol not found
if [[ "${bb_full_target}" == x86_64-linux-musl-*cxx03* ]]; then
    sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} PROTOC="$(which protoc)"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libprotobuf-c", :libprotobuf_c),
    ExecutableProduct("protoc-gen-c", :protoc_gen_c)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="protoc_jll", uuid="c7845625-083e-5bbe-8504-b32d602b7110"))
    HostBuildDependency("protoc_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
