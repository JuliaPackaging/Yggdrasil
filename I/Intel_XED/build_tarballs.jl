# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Intel_XED"
version = v"2023.08.21"

# Collection of sources required to build hwloc
sources = [
    GitSource("https://github.com/intelxed/xed", "01a6da8090af84cd52f6c1070377ae6e885b078f"),
    # mbuild is the build system for XED; we use v2022.07.28
    GitSource("https://github.com/intelxed/mbuild", "75cb46e6536758f1a3cdb3d6bd83a4a9fd0338bb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xed

# This file is binary (?), and Python tries to decode it as UTF-8 and fails, and aborts
# This file exists when I build locally, but not when Yggdrasil builds.
rm -f /usr/lib/python3.9/site-packages/._distutils-precedence.pth

python3 mfile.py --clean
python3 mfile.py -j${nproc} --cc=${CC} --opt=2 --shared --no-werror
# We could also build the CLI.

mkdir -p ${includedir}
mkdir -p ${libdir}
install -Dvm 755 obj/wkit/include/xed/*.h ${includedir}
install -Dvm 755 obj/wkit/lib/*.so ${libdir}
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# This package works only on x86/x86_64
filter!(p -> arch(p) ∈ ["i686", "x86_64"], platforms)
# While x86 should work it's broken
filter!(p -> arch(p) ≠ "i686", platforms)
# Darwin and Windows are not supported
filter!(p -> !Sys.iswindows(p) && !Sys.isapple(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxed", :libxed),
    LibraryProduct("libxed-ild", :libxed_ild),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
