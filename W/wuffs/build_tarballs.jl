# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wuffs"
version = v"0.3.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/wuffs", "ec71f9c6d829ca763fbbc1f7adecc30a89a8ed0a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wuffs
# wuffs is very simple: there is a single C source file and nothing else.
${CC} -c -DWUFFS_IMPLEMENTATION -fPIC -O3 release/c/wuffs-v0.3.c
${CC} -shared -o libwuffs.${dlext} wuffs-v0.3.o
install -Dvm 0755 libwuffs.${dlext} ${libdir}/libwuffs.${dlext}
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The build system (#ifdefs) in the source code does not handle our Windows setup
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libwuffs", :libwuffs)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 5 for i686 assembler intrinsics
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
