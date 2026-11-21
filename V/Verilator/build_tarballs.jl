# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Verilator"
version_string = "5.054"
version = VersionNumber(version_string)

sources = [
    GitSource("https://github.com/verilator/verilator.git",
              "bbb60a403932a9f695cb6ff001ceb73de6ad9234";
              tag="v$(version_string)"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/verilator
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/configure-cxx14-cross.patch
autoconf
# configure takes FlexLexer.h from next to `flex`; the rootfs flex comes without it
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} LEX=${host_bindir}/flex
# `make install` also builds the man pages, which need help2man
make -j${nproc} verilator_exe
make installbin installredirect installdata
# Debug builds (-ggdb) and examples aren't needed to run Verilator
rm -v ${bindir}/verilator_bin_dbg ${bindir}/verilator_coverage_bin_dbg
rm -v ${prefix}/share/verilator/bin/verilator_bin_dbg ${prefix}/share/verilator/bin/verilator_coverage_bin_dbg
rm -rv ${prefix}/share/verilator/examples
# Verilator is LGPL-3.0-only OR Artistic-2.0; installed headers also carry IEEE-1800 and MIT texts
install_license LICENSE LICENSES/*
"""

# C++17 aligned operator new/delete (std::align_val_t) are only in libc++ from macOS 10.14
sources, script = require_macos_sdk("10.14", sources, script)

platforms = supported_platforms()
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
    # verilator_bin links libatomic
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
]

# configure builds with the newest of -std=gnu++17/c++17/gnu++14/c++14 that the compiler
# accepts; GCC 7 is the first with full C++17, which upstream says is what it regularly tests
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")
