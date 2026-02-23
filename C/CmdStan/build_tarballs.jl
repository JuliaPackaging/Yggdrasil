# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CmdStan"
version = v"2.36.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/stan-dev/cmdstan.git", "61c4a75ca469617a2ec36b5329d0e518b67d6f36"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cmdstan*
cp ../local make/
git submodule update --init --recursive

if [[ "${target}" == i686* ]]; then
    echo "BITS=32" >> make/local
fi
if [[ "${target}" == *-mingw32 ]]; then
    target="windows"
elif [[ "${target}" == *-linux* ]]; then
    target="linux"
elif [[ "${target}" == *-apple* ]]; then
    target=macos
elif [[ "${target}" == *-freebsd ]]; then
    target="FreeBSD"
fi

make -j${nproc} build
cp -R bin/ $prefix/bin/ 
install_license ${WORKSPACE}/srcdir/cmdstan*/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
build_platforms = Platform[
    Platform("x86_64", "Linux"),
]
platforms = expand_cxxstring_abis(build_platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("diagnose", :diagnose),
    ExecutableProduct("stanc", :stanc),
    ExecutableProduct("stansummary", :stansummary)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9", julia_compat="1.6")
