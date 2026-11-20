# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "IVerilog"
version = v"13.0.0"

# Collection of sources required to complete build
sources = [
   GitSource("https://github.com/steveicarus/iverilog.git", "dfeee909ed9f20b4870dd93423156c0170c0e1ff")
]

# Bash recipe for building across all platforms
script = raw"""
cd iverilog
# Helper programs run during the build are compiled with the build compiler, so
# they must not get the target's linker flags (`-Wl,-all_load` on macOS).
sed -i 's/$(BUILDCC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS)/$(BUILDCC) $(CPPFLAGS) $(CFLAGS)/' Makefile.in vvp/Makefile.in
export CFLAGS="-O2"
export CXXFLAGS="-O2"
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

dependencies = [
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("gperf_jll"),
    Dependency("Readline_jll"; compat="8.1.1"),
    # On macOS, link the system zlib like bzip2 and readline. `iverilog` starts
    # `ivl` through `/bin/sh`, which drops `DYLD_*` variables, so `ivl` could not
    # load VPI modules that need `Zlib_jll`'s library.
    Dependency("Zlib_jll"; compat="1.2.12", platforms=filter(!Sys.isapple, platforms)),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("iverilog", :iverilog),
    ExecutableProduct("iverilog-vpi", :iverilog_vpi),
    ExecutableProduct("vvp", :vvp)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
