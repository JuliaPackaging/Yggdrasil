# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "likwid"
version = v"5.2.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/RRZE-HPC/likwid/archive/refs/tags/v$(version).tar.gz", "7dda6af722e04a6c40536fc9f89766ce10f595a8569b29e80563767a6a8f940e"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd likwid-*
if [[ "${target}" == powerpc64le-linux-* ]]; then
    export COMPILER=GCCPOWER
elif [[ "${target}" == aarch64-linux-* ]]; then
    export COMPILER=GCCARMv8
elif [[ "${target}" == armv7l-linux-* ]]; then
    export COMPILER=GCCARMv7
elif [[ "${target}" == i686-linux-* ]]; then
    export COMPILER=GCCX86
else # assume x86_64
    export COMPILER=GCC
fi
make PREFIX=${prefix} HWLOC_INCLUDE_DIR=${includedir} HWLOC_LIB_DIR=${libdir} HWLOC_LIB_NAME=hwloc LUA_INCLUDE_DIR=${includedir} LUA_LIB_DIR=${libdir} LUA_LIB_NAME=lua LUA_BIN=${bindir}
make install PREFIX=${prefix} HWLOC_INCLUDE_DIR=${includedir} HWLOC_LIB_DIR=${libdir} HWLOC_LIB_NAME=hwloc LUA_INCLUDE_DIR=${includedir} LUA_LIB_DIR=${libdir} LUA_LIB_NAME=lua LUA_BIN=${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liblikwidpin", :liblikwidpin),
    LibraryProduct("liblikwid", :liblikwid),
    ExecutableProduct("likwid-bench", :likwid_bench)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8"))
    Dependency(PackageSpec(name="Lua_jll", uuid="a4086b1d-a96a-5d6b-8e4f-2030e6f25ba6"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
