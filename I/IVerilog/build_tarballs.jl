# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "IVerilog"
version = v"12.0.0"

# Collection of sources required to complete build
sources = [
   GitSource("https://github.com/steveicarus/iverilog.git", "2693dd32b075243cca20400cf3a808cef119477e")
]

dependencies = [
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("gperf_jll"),
    Dependency("Readline_jll"; compat="8.1.1"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Bash recipe for building across all platforms
script = raw"""
cd iverilog
sh ./autoconf.sh
# The generated configure script is replacing a variable incorrectly
sed -i 's/EXEEXT=$ac_cv_build_exeext/BUILD_EXEEXT=$ac_cv_build_exeext/' configure
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("iverilog", :iverilog),
    ExecutableProduct("iverilog-vpi", :iverilog_vpi),
    ExecutableProduct("vvp", :vvp)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
