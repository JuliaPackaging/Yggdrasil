# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libblastrampoline"
version = v"5.8.0"

# Collection of sources required to build libblastrampoline
sources = [
    GitSource("https://github.com/JuliaLinearAlgebra/libblastrampoline.git",
              "81316155d4838392e8462a92bcac3eebe9acd0c7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libblastrampoline/src

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

make -j${nproc} prefix=${prefix} install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libblastrampoline", :libblastrampoline)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("LLVMCompilerRT_jll"; platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10"
)
