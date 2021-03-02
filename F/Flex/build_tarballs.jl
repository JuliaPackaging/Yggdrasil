# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Flex"
version = v"2.6.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/westes/flex.git", "d69a58075169410324fe49666f6641ba6a9d1f91")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd flex
apk add texinfo
apk add help2man
./autogen.sh
./configure --prefix=${prefix} --host=${target}
make -j${nprocs}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> (!Sys.iswindows(p) &&
                         !Sys.isapple(p) &&
                         !Sys.isfreebsd(p) &&
                         !(arch(p) in (:armv7l, :powerpc64le, :aarch64))),
                         supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libfl", :libfl),
    ExecutableProduct("flex", :flex)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Gettext_jll", uuid="78b55507-aeef-58d4-861c-77aaff3498b1"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
