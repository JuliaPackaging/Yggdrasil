# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath("..", "..", "platforms", "macos_sdks.jl"))

name = "OSRM"
version = v"26.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Project-OSRM/osrm-backend.git", "d3e0a354350b3e370e9124d43bcf6e22e85cf11c"),
    get_macos_sdk_sources("14.5")...,
]

script = raw"""
cd ${WORKSPACE}/srcdir/osrm-backend

# Common cmake flags
CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_PREFIX_PATH=${prefix}
    -DBUILD_SHARED_LIBS=ON
)

# Linux specific handling
if [[ "${target}" == *-linux-* ]]; then
    ### CMake flags
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-Wno-array-bounds -Wno-uninitialized -Wno-shift-count-overflow -Wno-error")

    if [[ "${target}" == *-linux-musl* ]]; then
        ### OSRM-backend Patching
        sed -i 's/-Wpedantic/-Wno-pedantic/g; s/-Werror=pedantic/-Wno-error=pedantic/g' CMakeLists.txt

        ### CMake flags
        CMAKE_FLAGS+=(
            -DOSRM_HAS_STD_FORMAT_EXITCODE=0
            -DOSRM_HAS_STD_FORMAT_EXITCODE__TRYRUN_OUTPUT=""
        )
    fi
fi

# Apple specific handling
if [[ "${target}" == *-apple-darwin* ]]; then
    ### SDK extraction — extract to a separate directory and point the toolchain at it
    apple_sdk_root=${WORKSPACE}/srcdir/MacOSX14.5.sdk
    mkdir -p "${apple_sdk_root}"
    echo "Extracting MacOSX14.5.sdk.tar.xz (this may take a while)"
    tar --extract \
        --file=${WORKSPACE}/srcdir/MacOSX14.5.sdk.tar.xz \
        --directory="${apple_sdk_root}" \
        --strip-components=1 \
        --warning=no-unknown-keyword \
        MacOSX14.5.sdk/System \
        MacOSX14.5.sdk/usr
    sed -i "s!/opt/${target}/${target}/sys-root!${apple_sdk_root}!" ${CMAKE_TARGET_TOOLCHAIN}
    sed -i "s!/opt/${target}/${target}/sys-root!${apple_sdk_root}!" /opt/bin/${bb_full_target}/${target}-clang++
    export MACOSX_DEPLOYMENT_TARGET=14.5

    ### CMake flags
    CMAKE_FLAGS+=(
        -DENABLE_LTO=OFF
        -DCMAKE_EXE_LINKER_FLAGS="-L${libdir} -ltbb -lz"
        -DCMAKE_SHARED_LINKER_FLAGS="-L${libdir} -ltbb -lz"
        -DBoost_DIR=${libdir}/cmake/Boost-1.87.0/
        -DTBB_DIR=${libdir}/cmake/TBB
        -DLUA_LIBRARIES="${libdir}/liblua.dylib"
        -DLUA_INCLUDE_DIR="${includedir}"
        -DOSRM_HAS_STD_FORMAT_EXITCODE=0
        -DOSRM_HAS_STD_FORMAT_EXITCODE__TRYRUN_OUTPUT=""
    )
fi

# Windows specific handling
if [[ "${target}" == *-mingw* ]]; then
    ### CMake flags
    LTO_FLAGS="-fno-lto"
    CMAKE_FLAGS+=(
        -DENABLE_LTO=OFF
        -DCMAKE_CXX_FLAGS="-Wno-array-bounds -Wno-uninitialized -Wno-unused-parameter -Wno-maybe-uninitialized -Wno-shift-count-overflow ${LTO_FLAGS} -Wno-error -Wno-pedantic"
        -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG ${LTO_FLAGS}"
        -DCMAKE_EXE_LINKER_FLAGS="${LTO_FLAGS} -Wl,-subsystem,console -L${libdir} -ltbb12 -lz"
        -DCMAKE_SHARED_LINKER_FLAGS="${LTO_FLAGS} -Wl,--export-all-symbols -L${libdir} -ltbb12 -lz"
        -DCMAKE_CXX_VISIBILITY_PRESET=default
        -DCMAKE_VISIBILITY_INLINES_HIDDEN=OFF
        -DCMAKE_SKIP_RPATH=ON
        -DOSRM_HAS_STD_FORMAT_EXITCODE=0
        -DOSRM_HAS_STD_FORMAT_EXITCODE__TRYRUN_OUTPUT=""
        -DBoost_DIR=${libdir}/cmake/Boost-1.87.0/
        -DTBB_DIR=${libdir}/cmake/TBB
        -DLUA_LIBRARIES="lua54"
        -DLUA_INCLUDE_DIR="${includedir}"
    )
fi

mkdir build && cd build

cmake .. "${CMAKE_FLAGS[@]}"

cmake --build . --parallel ${nproc}
cmake --install .

# Windows: Regenerate import library with proper symbols
if [[ "${target}" == *-mingw* ]]; then
    if [ -f ${prefix}/bin/libosrm.dll ] && [ -f ${prefix}/lib/libosrm.dll.a ]; then
        cd ${prefix}/lib
        # Extract exported symbols from DLL - nm -D shows dynamically exported symbols
        nm -D ${prefix}/bin/libosrm.dll 2>/dev/null | awk '/^[0-9a-fA-F]+ [Tt] / {print $3}' > /tmp/libosrm.def
        if [ -s /tmp/libosrm.def ]; then
            # Create proper .def file format with EXPORTS header
            echo "EXPORTS" > /tmp/libosrm.def.tmp
            cat /tmp/libosrm.def >> /tmp/libosrm.def.tmp
            mv /tmp/libosrm.def.tmp /tmp/libosrm.def
            # Regenerate import library from .def file
            dlltool -d /tmp/libosrm.def -l libosrm.dll.a -D ${prefix}/bin/libosrm.dll
            rm -f /tmp/libosrm.def
        fi
    fi
fi

cp -r ${WORKSPACE}/srcdir/osrm-backend/profiles ${prefix}/
install_license "${WORKSPACE}/srcdir/osrm-backend/LICENSE.TXT"
"""

platforms = supported_platforms()
platforms = filter(p -> !Sys.isfreebsd(p), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("osrm-extract", :osrm_extract),
    ExecutableProduct("osrm-contract", :osrm_contract),
    ExecutableProduct("osrm-partition", :osrm_partition),
    ExecutableProduct("osrm-customize", :osrm_customize),
    ExecutableProduct("osrm-routed", :osrm_routed),
    ExecutableProduct("osrm-datastore", :osrm_datastore),
    ExecutableProduct("osrm-components", :osrm_components),
    ExecutableProduct("osrm-io-benchmark", :osrm_io_benchmark),
    LibraryProduct("libosrm", :libosrm; dont_dlopen = true),  # Cannot be loaded in sandbox
    FileProduct("profiles/bicycle.lua", :bicycle_lua),
    FileProduct("profiles/car.lua", :car_lua),
    FileProduct("profiles/foot.lua", :foot_lua),
    FileProduct("profiles/lib/access.lua", :lib_access_lua),
    FileProduct("profiles/lib/maxspeed.lua", :lib_maxspeed_lua),
    FileProduct("profiles/lib/profile_debugger.lua", :lib_profile_debugger_lua),
    FileProduct("profiles/lib/set.lua", :lib_set_lua),
    FileProduct("profiles/lib/utils.lua", :lib_utils_lua),
    FileProduct("profiles/lib/destination.lua", :lib_destination_lua),
    FileProduct("profiles/lib/measure.lua", :lib_measure_lua),
    FileProduct("profiles/lib/relations.lua", :lib_relations_lua),
    FileProduct("profiles/lib/tags.lua", :lib_tags_lua),
    FileProduct("profiles/lib/way_handlers.lua", :lib_way_handlers_lua),
    FileProduct("profiles/lib/guidance.lua", :lib_guidance_lua),
    FileProduct("profiles/lib/obstacles.lua", :lib_obstacles_lua),
    FileProduct("profiles/lib/pprint.lua", :lib_pprint_lua),
    FileProduct("profiles/lib/sequence.lua", :lib_sequence_lua),
    FileProduct("profiles/lib/traffic_signal.lua", :lib_traffic_signal_lua),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat = "~1.87.0"),
    Dependency("Lua_jll"; compat = "~5.4.9"),
    Dependency("oneTBB_jll"; compat = "2022.0.0"),
    Dependency("Expat_jll"; compat = "2.6.5"),
    Dependency("Bzip2_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.10", preferred_gcc_version = v"13"
)
