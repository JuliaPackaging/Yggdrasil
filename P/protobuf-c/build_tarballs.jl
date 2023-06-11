# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "protobuf_c"
version = v"1.4.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/protobuf-c/protobuf-c/releases/download/v$(version)/protobuf-c-$(version).tar.gz", "4cc4facd508172f3e0a4d3a8736225d472418aee35b4ad053384b137b220339f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/protobuf-c*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl")
]

# platforms = supported_platforms()
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
