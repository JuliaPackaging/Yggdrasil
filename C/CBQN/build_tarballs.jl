# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CBQN"
version = v"2022.11.8"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dzaima/CBQN.git", "4f9af9965c8c8fbb90b79168fa529ebe4124622c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CBQN/

# Yes, the build systems fiddles with git remotes names, so we need to make it happy.  Sigh.
git remote rename origin bb
git remote add origin https://github.com/dzaima/CBQN.git
git fetch origin

make shared-o3 C_INCLUDE_PATH="${prefix}/lib/libffi-3.2.1/include"
install -Dvm 0755 "libcbqn.${dlext}" "${libdir}/libcbqn.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcbqn", :libcbqn),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libffi_jll", uuid="e9f186c6-92d2-5b65-8a66-fee21dc1b490"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
