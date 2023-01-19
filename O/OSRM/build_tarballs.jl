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

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)
CMAKE_FLAGS+=(-Wno-dev)

# mingw demands extra flags
if [[ "${target}" == *mingw* ]]; then
    CMAKE_FLAGS+=(-DLUA_INCLUDE_DIR=${includedir})
    CMAKE_FLAGS+=(-DLUA_LIBRARIES=${libdir}/liblua.${dlext})
elif [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Work around the issue
    # /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/local/include/tbb/../oneapi/tbb/detail/_task.h:216:13: error: aligned deallocation function of type 'void (void *, std::align_val_t) noexcept' is only available on macOS 10.14 or newer
    export MACOSX_DEPLOYMENT_TARGET=10.15
    # ...and install a newer SDK
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

cmake .. ${CMAKE_FLAGS[@]}
cmake --build . -j${nproc}
cmake --build . -j${nproc} --target install

cp osrm-* ${bindir}
cp libosrm* ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# oneTBB_jll isn't available for Windows i686 on Yggdrasil (version 2021.5.0)
# oneTBB_jll isn't available for armv6l, armv7l
# musl builds with lots of TBB errors like 'undefined reference to `getcontext''
platforms = supported_platforms(; exclude=p -> 
    (Sys.iswindows(p) &&
    arch(p) == "i686") ||
    (libc(p) == "musl") ||
    (arch(p) == "armv6l") ||
    (arch(p) == "armv6l")
    )

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
    LibraryProduct("libosrm", :libosrm)
    LibraryProduct("libosrm_contract", :libosrm_contract)
    LibraryProduct("libosrm_customize", :libosrm_customize)
    LibraryProduct("libosrm_extract", :libosrm_extract)
    LibraryProduct("libosrm_guidance", :libosrm_guidance)
    LibraryProduct("libosrm_partition", :libosrm_partition)
    LibraryProduct("libosrm_store", :libosrm_store)
    LibraryProduct("libosrm_update", :libosrm_update)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.8")
    Dependency("boost_jll"; compat="=1.76.0")
    Dependency("Expat_jll"; compat="2.2.10")
    Dependency("XML2_jll")
    Dependency("oneTBB_jll"; platforms=filter(p -> (arch(p) ∉ ("armv6l", "armv7l")) & (!Sys.iswindows(p) || arch(p) != "i686"), platforms))
    Dependency("Lua_jll"; compat="~5.4.3")
    HostBuildDependency("Lua_jll")
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
