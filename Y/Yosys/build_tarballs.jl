# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Yosys"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/YosysHQ/yosys.git", "2e421feb0ea526468493ab008f3c72beb12c2bc6")
]

dependencies = [
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
    Dependency("Readline_jll"),
    Dependency("Tcl_jll"),
    Dependency("Zlib_jll"; compat="~1.2.11"),
    Dependency("Libffi_jll"; compat="~3.2.2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd yosys
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    CONFIG=clang
else
    CONFIG=gcc
fi
make CONFIG=${CONFIG} PREFIX=${prefix} -j${nproc}
make install PREFIX=${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.isapple(p) || Sys.islinux(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)
# For some reasons, building for CXX03 string ABI doesn't actually work, skip it
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = Product[
	ExecutableProduct("yosys", :yosys)
	ExecutableProduct("yosys-config", :yosys_config)
	ExecutableProduct("yosys-filterlib", :yosys_filterlib)
	ExecutableProduct("yosys-smtbmc", :yosys_smtbmc)
	ExecutableProduct("yosys-abc", :yosys_abc)
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
