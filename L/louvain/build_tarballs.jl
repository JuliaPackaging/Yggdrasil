# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "louvain"
version = v"0.2.0" # Rebuilding louvain_jll to include macOS aarch64

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/KrainskiL/louvain.git", "3e9efdb930efc4a3715d0978ea08ed52172f7231")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/louvain/
make -j${nproc}
for exe in hierarchy louvain matrix convert; do
    install -Dvm 755 "${exe}" "${bindir}/${exe}${exeext}"
done
install_license *gpl*.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("hierarchy", :hierarchy),
    ExecutableProduct("louvain", :louvain),
    ExecutableProduct("convert", :convertlouvain)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
