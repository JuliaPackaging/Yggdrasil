# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Yosys"
version = v"0.34.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/YosysHQ/yosys.git", "4a1b5599258881f579a2d95274754bcd8fc171bd")
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())
platforms = expand_cxxstring_abis(platforms)
# For some reasons, building for CXX03 string ABI doesn't actually work, skip it
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

dependencies = [
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
    Dependency("Readline_jll"; compat="8.1.1"),
    Dependency("Tcl_jll"; compat="8.6.11"),
    Dependency("Zlib_jll"; compat="1.2.11"),
    Dependency("Libffi_jll"; compat="~3.2.2"),
    Dependency("dlfcn_win32_jll"; compat="1.3.1", platforms=filter(Sys.iswindows, platforms))
]

# Bash recipe for building across all platforms
script = raw"""
cd yosys

if [[ "${target}" == *-apple-* ]]; then
    CONFIG=clang
    OS=Darwin
elif [[ "${target}" == *-freebsd* ]]; then
    CONFIG=clang
    OS=FreeBSD
elif [[ "${target}" == *x86_64-w64-mingw32* ]]; then
    CONFIG=msys2-64
    OS=Windows
elif [[ "${target}" == *i686-w64-mingw32* ]]; then
    CONFIG=msys2-32
    OS=Windows
else
    CONFIG=gcc
    OS=Linux
fi

# TODO: ABC does not build on windows
if [[ "${target}" == *x86_64-w64-mingw32* ]] || [[ "${target}" == *i686-w64-mingw32* ]]; then
    make install ENABLE_LIBYOSYS=1 ENABLE_ABC=0 ENABLE_TCL=0 OS=${OS} CONFIG=${CONFIG} PREFIX=${prefix} TCL_INCLUDE=${libdir} TCL_VERSION=tcl86 LIBDIR=${libdir} -j${nproc}
else
    make install ENABLE_LIBYOSYS=1 OS=${OS} CONFIG=${CONFIG} PREFIX=${prefix} TCL_INCLUDE=${libdir} LIBDIR=${libdir} -j${nproc}
fi

# everything is a .so even if it is not... so fixup
mv ${libdir}/libyosys.so  ${libdir}/libyosys.${dlext}
"""

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("yosys", :yosys),
    ExecutableProduct("yosys-filterlib", :yosys_filterlib),
    LibraryProduct("libyosys", :libyosys)
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
