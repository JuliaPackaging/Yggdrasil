# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CmdStan"
version = v"2.26.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/stan-dev/cmdstan/releases/download/v$(version)/cmdstan-$(version).tar.gz", "d944d23ac7ed5ebf924d859f3a1f3052891161e2c70313503f21257ea13f0b0c"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/cmdstan-*
cp ../local make/
if [[ "${target}" == *-mingw32 ]]; then
    target="windows"
elif [[ "${target}" == *-linux* ]]; then
    target="linux"
elif [[ "${target}" == *-apple* ]]; then
    target=macos
elif [[ "${target}" == *-freebsd ]]; then
    target="FreeBSD"
fi
echo $target
make -j${nproc} build
cp -R bin/ $prefix/bin/ 
install_license ${WORKSPACE}/srcdir/cmdstan-*/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
