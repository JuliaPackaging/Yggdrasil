# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OSRM"
version = v"5.28.0" # UNTAGGED / ASK FOR NEW RELEASE TAG

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Project-OSRM/osrm-backend.git", "c59ad69d6a081fb0c8fca9fe7bf798d4150ea8d2"),
    DirectorySource("./bundled"),
    # OSRM requires C++20, which needs a newer SDK
    ArchiveSource("https://github.com/realjf/MacOSX-SDKs/releases/download/v0.0.1/MacOSX12.3.sdk.tar.xz",
                  "a511c1cf1ebfe6fe3b8ec005374b9c05e89ac28b3d4eb468873f59800c02b030"),    
]

sdk_update_script = raw"""
if [[ "${target}" == *-apple-darwin* ]]; then
    # Install a newer SDK which supports C++20
    pushd $WORKSPACE/srcdir/MacOSX12.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/*
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    export MACOSX_DEPLOYMENT_TARGET=12.3
fi
"""

# Bash recipe for building across all platforms
script = sdk_update_script * raw"""
cd $WORKSPACE/srcdir/osrm-backend

# Use boost patch, drop once https://github.com/Project-OSRM/osrm-backend/pull/7073 is merged
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/boost_1_87.patch"

# Patch CMakeLists.txt
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/cmake_fixes.patch"

if [[ ${target} == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mingw.patch"

    # oneTBB requires at least Windows Vista/Server 2008:
    # https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createsemaphoreexa
    export CXXFLAGS="-D_WIN32_WINNT=0x0600"
fi

CFLAGS="-Wno-array-bounds -Wno-error=suggest-override -Wno-error=deprecated-declarations -Wno-error=stringop-overflow -Wno-error=uninitialized -Wno-error=array-bounds"
mkdir build && cd build

export AR=$HOSTAR

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)
CMAKE_FLAGS+=(-DENABLE_CCACHE=OFF)
CMAKE_FLAGS+=(-Wno-dev)
CMAKE_FLAGS+=(-DENABLE_MASON=OFF)
CMAKE_FLAGS+=(-DZLIB_INCLUDE_DIRS=${includedir})
CMAKE_FLAGS+=(-DCMAKE_AR=$HOSTAR)
CMAKE_FLAGS+=(-DZLIB_LIBRARY=${libdir}/libz.${dlext})
CMAKE_FLAGS+=(-DENABLE_LTO=OFF)

if [[ ${target} == *mingw* ]]; then
    CMAKE_FLAGS+=(-DLUA_INCLUDE_DIR=${includedir})
    CMAKE_FLAGS+=(-DLUA_LIBRARIES=${libdir}/liblua.${dlext})
    CMAKE_FLAGS+=(-D__TBB_USE_FENV=0)
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-fext-numeric-literals -Wno-array-bounds -Wno-error=suggest-override -Wno-error=deprecated-declarations -Wno-error=stringop-overflow -Wno-error=uninitialized -Wno-error=array-bounds")
else
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-Wno-array-bounds -Wno-error=suggest-override -Wno-error=deprecated-declarations -Wno-error=stringop-overflow -Wno-error=uninitialized -Wno-error=array-bounds")
fi

cmake .. ${CMAKE_FLAGS[@]}
cmake --build . -j${nproc}
cmake --build . -j${nproc} --target install

cp osrm-* ${bindir}
cp libosrm* ${libdir}

cp ../profiles/*.lua ${prefix}
cp ../profiles/lib/*.lua ${prefix}/lib

install_license ../LICENSE.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# 32 bit platforms are not supported
# oneTBB_jll isn't available for Windows i686 on Yggdrasil (version 2021.5.0)
# oneTBB_jll isn't available for armv6l, armv7l
# musl builds with lots of TBB errors like 'undefined reference to `getcontext''
platforms = supported_platforms(; exclude=p -> (nbits(p) == 32))
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
    # We are not dlopening because the build images use Julia 1.7, which can't dlopen SOs built
    # with GCC 12, which is required for OSRM. However, Julia 1.8+ can dlopen them (tested),
    # and that is what our compat entry says, so the dlopen failure can safely be ignored.
    LibraryProduct("libosrm", :libosrm, dont_dlopen=true)
    FileProduct("bicycle.lua", :bicycle)
    FileProduct("debug_way.lua", :debug_way)
    FileProduct("test.lua", :test)
    FileProduct("car.lua", :car)
    FileProduct("rasterbot.lua", :rasterbot)
    FileProduct("testbot.lua", :testbot)
    FileProduct("debug_example.lua", :debug_example)
    FileProduct("foot.lua", :foot)
    FileProduct("rasterbotinterp.lua", :rasterbotinterp)
    FileProduct("turnbot.lua", :turnbot)
    FileProduct("lib/access.lua", :lib_access)
    FileProduct("lib/maxspeed.lua", :lib_maxspeed)
    FileProduct("lib/profile_debugger.lua", :lib_profile_debugger)
    FileProduct("lib/set.lua", :lib_set)
    FileProduct("lib/utils.lua", :lib_utils)
    FileProduct("lib/destination.lua", :lib_destination)
    FileProduct("lib/measure.lua", :lib_measure)
    FileProduct("lib/relations.lua", :lib_relations)
    FileProduct("lib/tags.lua", :lib_tags)
    FileProduct("lib/way_handlers.lua", :lib_way_handlers)
    FileProduct("lib/guidance.lua", :lib_guidance)
    FileProduct("lib/pprint.lua", :lib_pprint)
    FileProduct("lib/sequence.lua", :lib_sequence)
    FileProduct("lib/traffic_signal.lua", :lib_traffic_signal)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.9")
    Dependency("boost_jll"; compat="=1.87.0") # Earlier versions of boost seem uncompatible with C++20 deprecations
    Dependency("Expat_jll"; compat="2.6.5")
    Dependency("XML2_jll")
    Dependency("oneTBB_jll"; compat="2021.12.0")
    Dependency("Lua_jll"; compat="~5.4.3")
    Dependency("Zlib_jll")
    HostBuildDependency("Lua_jll")
    # Dependency("libosmium_jll")
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8", preferred_gcc_version=v"13", clang_use_lld=false)
