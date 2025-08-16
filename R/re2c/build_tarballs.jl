# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "re2c"
version_string = "4.3"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/skvadrik/re2c/releases/download/$(version_string)/re2c-$(version_string).tar.xz",
                  "51e88d6d6b6ab03eb7970276aca7e0db4f8e29c958b84b561d2fdcb8351c7150"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/re2c-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j$nproc
make install
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("re2c", :re2c),
    ExecutableProduct("re2d", :re2d),
    ExecutableProduct("re2go", :re2go),
    ExecutableProduct("re2hs", :re2hs),
    # ExecutableProduct("re2java", :re2java),
    ExecutableProduct("re2js", :re2js),
    ExecutableProduct("re2ocaml", :re2ocaml),
    ExecutableProduct("re2py", :re2py),
    ExecutableProduct("re2rust", :re2rust),
    ExecutableProduct("re2swift", :re2swift),
    ExecutableProduct("re2v", :re2v),
    # ExecutableProduct("re2zig", :re2zig),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
