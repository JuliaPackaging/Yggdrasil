# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Yosys"
version = v"0.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/YosysHQ/yosys.git", "2e421feb0ea526468493ab008f3c72beb12c2bc6")
]

dependencies = [
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
    Dependency("Readline_jll"),
    Dependency("Tcl_jll"),
    Dependency("Zlib_jll"),
    Dependency("ABC_jll"),
    Dependency("Libffi_jll"; compat="~3.2.2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd yosys
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    CONFIG=clang
    OS=Darwin
elif [[ "${target}" == *-x86_64-w64-mingw32* ]]; then
    CONFIG=msys2-64
    OS=Windows
elif [[ "${target}" == *-i686-w64-mingw32* ]]; then
    CONFIG=msys2-32
    OS=Windows
else
    CONFIG=gcc
    OS=Linux
fi
# TODO: we need mingw-dlfcn wrappers for windows plugin support
# TODO: ABC does not build on windows
make ENABLE_LIBYOSYS=1 OS=${OS} CONFIG=${CONFIG} PREFIX=${prefix} LIBDIR=${libdir} -j${nproc}
make install ENABLE_LIBYOSYS=1 OS=${OS} PREFIX=${prefix} LIBDIR=${libdir}
if [[ "${target}" == *-apple-* ]]; then
    mv ${prefix}/lib/libyosys.so  ${prefix}/lib/libyosys.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.isapple(p) || Sys.islinux(p), supported_platforms())
platforms = expand_cxxstring_abis(platforms)
# For some reasons, building for CXX03 string ABI doesn't actually work, skip it
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("yosys", :yosys),
    ExecutableProduct("yosys-config", :yosys_config),
    ExecutableProduct("yosys-filterlib", :yosys_filterlib),
    ExecutableProduct("yosys-smtbmc", :yosys_smtbmc),
    ExecutableProduct("yosys-abc", :yosys_abc),
    LibraryProduct("libyosys", :libyosys)
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
