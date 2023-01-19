# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OSRM"
version = v"5.28.0" # UNTAGGED / ASK FOR NEW RELEASE TAG

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Project-OSRM/osrm-backend.git", "d9df33dd0a492c50632deddd0ddfdfbf3cb5bbd7"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/osrm-backend

# Patch boost/phoenix.hpp header path
atomic_patch -p1 ../patches/boost_deprecated_header.patch

CFLAGS="-Wno-error=suggest-override"

mkdir build && cd build

cmake .. \
    -DBZIP2_INCLUDE_DIR=${includedir} \
    -DBZIP2_LIBRARIES=${libdir}/libbz2.${dlext} \
    -DLUA_INCLUDE_DIR=${includedir} \
    -DLUA_LIBRARIES=${libdir}/liblua.${dlext} \
    -DZLIB_INCLUDE_DIR=${includedir} \
    -DZLIB_LIBRARY=${libdir}/libz.${dlext} \
    -Wno-dev
cmake --build . -j${nproc}
cmake --build . -j${nproc} --target install

cp osrm-* ${bindir}
cp libosrm_* ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("osrm-routed", :osrm_routed)
    ExecutableProduct("osrm-partition", :osrm_partition)
    ExecutableProduct("osrm-components", :osrm_components)
    ExecutableProduct("osrm-contract", :osrm_contract)
    ExecutableProduct("osrm-customize", :osrm_customize)
    ExecutableProduct("osrm-datastore", :osrm_datastore)
    ExecutableProduct("osrm-extract", :osrm_extract)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.8")
    Dependency("boost_jll"; compat="=1.76.0")
    Dependency("Expat_jll"; compat="2.2.10")
    Dependency("XML2_jll")
    Dependency("oneTBB_jll")
    Dependency("Lua_jll")
    HostBuildDependency("Lua_jll")
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
