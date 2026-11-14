# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Verilator"
version_string = "5.054"
version = VersionNumber(version_string)

sources = [
    GitSource("https://github.com/verilator/verilator.git",
              "bbb60a403932a9f695cb6ff001ceb73de6ad9234";
              tag="v$(version_string)"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/verilator
autoconf
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
# `make install` also builds the man pages, which need help2man
make -j${nproc} verilator_exe
make installbin installredirect installdata
install_license LICENSE
"""

# Not attempted on Windows
platforms = supported_platforms(; exclude=Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("verilator_bin", :verilator_bin),
    # Perl wrapper around verilator_bin; needs `perl` on the PATH
    ExecutableProduct("verilator", :verilator),
    FileProduct("share/verilator/include/verilated.h", :verilated_h),
]

dependencies = [
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("flex_jll"),
]

# Verilator needs C++14
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
