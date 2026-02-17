# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

name = "OpenVAF"
version = v"23.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pascalkuthe/OpenVAF.git", "a9697ae7780518f021f9f64e819b3a57033bd39f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/OpenVAF
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
export OPENVAF_LLVM_LIBNAMES="LLVM"
if [[ "${target}" == *-mingw* ]]; then
    export OPENVAF_LLVM_LIBNAMES="LLVM-16jl"
fi

LLVM_LINK_SHARED=1 LLVM_CONFIG="${host_prefix}/tools/llvm-config" OPENVAF_LLVM_LIBDIR="${libdir}" OPENVAF_LLVM_INCLUDEDIR="${includedir}" cargo build --release --bin openvaf

install -Dvm 0755 "target/${rust_target}/release/openvaf${exeext}" "${bindir}/openvaf${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

filter!(p -> arch(p) ∉ ("powerpc64le", "armv6l", "armv7l"), platforms)
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl" && arch(p) == "i686"), platforms) # fails to include "llvm/IR/Instructions.h"
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms) # undefined reference to `_Unwind_Resume'

# The products that we will ensure are always built
products = [
    ExecutableProduct("openvaf", :openvaf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(get_addable_spec("LLVM_full_jll", v"16.0.6+4")),
    Dependency("Libiconv_jll", platforms=filter(Sys.isapple, platforms)),
    Dependency(get_addable_spec("LLVM_full_jll", v"16.0.6+4"); compat="16"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"9", # GCC >= 9 required for `-fuse-ld=lld`
               preferred_llvm_version=v"16.0.6", # This must match the version of LLVM above
               lock_microarchitecture=false, # Cargo sometimes inserts `-march` flags that we have to accept
               compilers=[:rust, :c])
