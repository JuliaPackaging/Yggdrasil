# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "IVerilog"
version = v"11.0.0"

# Collection of sources required to complete build
sources = [
   GitSource("https://github.com/steveicarus/iverilog.git", "84b4ebee0cfcda28a242d89a07020cd70b1d3e7f")
]

dependencies = [
    Dependency("Bison_jll"; compat="~3.5.2"),
    Dependency("Readline_jll"; compat="~8.1.1"),
    Dependency("gperf_jll"; compat="~3.1.0"),
    Dependency("Zlib_jll"; compat="~1.2.11"),
]

# Bash recipe for building across all platforms
script = raw"""
cd iverilog
export CPPFLAGS="-I${includedir}"
sh ./autoconf.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-zlib=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) == "x86_64" && Sys.islinux(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)
# For some reason, building for CXX03 string ABI doesn't actually work, skip it

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("iverilog", :iverilog),
    ExecutableProduct("iverilog-vpi", :iverilog_vpi)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
