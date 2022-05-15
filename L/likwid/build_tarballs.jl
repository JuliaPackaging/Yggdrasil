# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "likwid"
version = v"5.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/RRZE-HPC/likwid/archive/refs/tags/v$(version).tar.gz", "1b8e668da117f24302a344596336eca2c69d2bc2f49fa228ca41ea0688f6cbc2"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd likwid-5.2.1/
make PREFIX=${prefix} HWLOC_INCLUDE_DIR=${includedir} HWLOC_LIB_DIR=${libdir} HWLOC_LIB_NAME=hwloc LUA_INCLUDE_DIR=${includedir} LUA_LIB_DIR=${libdir} LUA_LIB_NAME=lua LUA_BIN=${bindir}
make install PREFIX=${prefix} HWLOC_INCLUDE_DIR=${includedir} HWLOC_LIB_DIR=${libdir} HWLOC_LIB_NAME=hwloc LUA_INCLUDE_DIR=${includedir} LUA_LIB_DIR=${libdir} LUA_LIB_NAME=lua LUA_BIN=${bindir}
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
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
