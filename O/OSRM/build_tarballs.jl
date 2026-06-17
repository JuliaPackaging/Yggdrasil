# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath("..", "..", "platforms", "macos_sdks.jl"))

name = "OSRM"
version = v"26.6.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Project-OSRM/osrm-backend.git",
        "d173ad3eb020900f3f111f2e1fcb4769d9100573"),  # v26.6.5
]

script = raw"""
cd ${WORKSPACE}/srcdir/osrm-backend

# Drop CMP0156 (CMake 3.29); BB's older CMake errors on it, default is fine.
sed -i '/cmake_policy(SET CMP0156 NEW)/d' CMakeLists.txt

# Drop the blanket -Werror; it overrides our -Wno-error and trips BB-GCC warnings.
sed -i '/add_warning(error)/d' cmake/warnings.cmake

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_PREFIX_PATH=${prefix}
    -DBUILD_SHARED_LIBS=ON
    -DFLATBUFFERS_FLATC_EXECUTABLE=${host_bindir}/flatc
    -DOSRM_HAS_STD_FORMAT_EXITCODE=0
    -DOSRM_HAS_STD_FORMAT_EXITCODE__TRYRUN_OUTPUT=""
)

if [[ "${target}" == *-linux-* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-Wno-array-bounds -Wno-uninitialized -Wno-shift-count-overflow -Wno-error")
fi

if [[ "${target}" == *-apple-darwin* ]]; then
    # Apple libc++ lacks std::atomic_ref (C++20); use a portable atomic CAS builtin.
    sed -i '/std::atomic_ref<uint64_t>/d' include/util/packed_vector.hpp
    sed -i 's/return atomic_ref.*/return __sync_bool_compare_and_swap(ptr, old_value, new_value);/' include/util/packed_vector.hpp
    CMAKE_FLAGS+=(
        -DENABLE_LTO=OFF
        -DCMAKE_EXE_LINKER_FLAGS="-L${libdir} -ltbb -lz"
        -DCMAKE_SHARED_LINKER_FLAGS="-L${libdir} -ltbb -lz"
        -DBoost_DIR=${libdir}/cmake/Boost-1.87.0/
        -DTBB_DIR=${libdir}/cmake/TBB
        -DLUA_LIBRARIES="${libdir}/liblua.dylib"
        -DLUA_INCLUDE_DIR="${includedir}"
    )
fi

if [[ "${target}" == *-mingw* ]]; then
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
    LibraryProduct("libosrm", :libosrm; dont_dlopen=true),  # Cannot be loaded in sandbox
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
    Dependency("boost_jll"; compat="=1.87.0"),
    Dependency("oneTBB_jll"; compat="2022.0.0"),
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("Bzip2_jll"),
    Dependency("Zlib_jll"),
    Dependency("Lua_jll"; compat="~5.4.9"),
    Dependency("LibArchive_jll"; compat="3.8.7"),
    BuildDependency("Fmt_jll"),
    BuildDependency("rapidjson_jll"),
    BuildDependency("Sol2_jll"),
    BuildDependency("protozero_jll"),
    BuildDependency("vtzero_jll"),
    BuildDependency("libosmium_jll"),
    BuildDependency("flatbuffers_jll"),
    # Host flatc to generate flatbuffers headers when cross-compiling.
    HostBuildDependency("flatbuffers_jll"),
]

sources, script = require_macos_sdk("14.5", sources, script)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10", preferred_gcc_version=v"13"
)
