# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath("..", "..", "platforms", "macos_sdks.jl"))
const SDK_VERSION = "14.5"

name = "OSRM"
version = v"6.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Project-OSRM/osrm-backend.git", "01605f7589e6fe68df3fc690ad001b687128aba7"),
    get_macos_sdk_sources(SDK_VERSION)...
]

script = raw"""
cd ${WORKSPACE}/srcdir/osrm-backend

# Common cmake flags
CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_CXX_STANDARD=20
    -DCMAKE_PREFIX_PATH=${prefix}
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_TESTING=OFF
)

# Linux specific handling
if [[ "${target}" == *-linux-* ]]; then
    ### CMake flags
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-Wno-array-bounds -Wno-uninitialized -Wno-error")

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
    ### SDK extraction
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX$(SDK_VERSION).sdk
    mkdir -p "$apple_sdk_root"
    echo "Extracting MacOSX$(SDK_VERSION).tar.xz (this may take a while)"
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX$(SDK_VERSION).tar.xz --directory="$apple_sdk_root" --strip-components=1 --warning=no-unknown-keyword MacOSX$(SDK_VERSION).sdk/System MacOSX$(SDK_VERSION).sdk/usr
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    export MACOSX_DEPLOYMENT_TARGET=$(SDK_VERSION)

    ### OSRM-backend Patching
    # Exclude duplicate intersection files from GUIDANCE for platforms that link to EXTRACTOR
    sed -i 's|file(GLOB GuidanceGlob src/guidance/\*\.cpp src/extractor/intersection/\*\.cpp)|file(GLOB GuidanceGlob src/guidance/*.cpp)|' CMakeLists.txt
    # Replace the osrm_guidance library definition with version that links to EXTRACTOR
    sed -i '/^add_library(osrm_guidance $<TARGET_OBJECTS:GUIDANCE> $<TARGET_OBJECTS:UTIL>)$/c\
add_library(osrm_guidance $<TARGET_OBJECTS:GUIDANCE> $<TARGET_OBJECTS:UTIL> $<TARGET_OBJECTS:MICROTAR>)\
target_link_libraries(osrm_guidance PRIVATE EXTRACTOR ${LUA_LIBRARIES} BZip2::BZip2 ZLIB::ZLIB EXPAT::EXPAT Boost::iostreams TBB::tbb)' CMakeLists.txt

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
    ### OSRM-backend Patching
    # Ensure console executables by stripping WIN32 from add_executable invocations
    find . -name "CMakeLists.txt" -o -name "*.cmake" | while read f; do
        sed -i '/add_executable(/,/)/{s/ WIN32//g;}' "$f"
        sed -i 's/add_executable(\([^ ]*\) WIN32 /add_executable(\1 /g' "$f"
        sed -i 's/add_executable(\([^ ]*\) WIN32)/add_executable(\1)/g' "$f"
    done
    # Remove rpath flag for Windows
    sed -i '/set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,origin")/d' CMakeLists.txt
    # Exclude duplicate intersection files from GUIDANCE for platforms that link to EXTRACTOR
    sed -i 's|file(GLOB GuidanceGlob src/guidance/\*\.cpp src/extractor/intersection/\*\.cpp)|file(GLOB GuidanceGlob src/guidance/*.cpp)|' CMakeLists.txt
    # Replace the osrm_guidance library definition with version that links to EXTRACTOR
    sed -i '/^add_library(osrm_guidance $<TARGET_OBJECTS:GUIDANCE> $<TARGET_OBJECTS:UTIL>)$/c\
add_library(osrm_guidance $<TARGET_OBJECTS:GUIDANCE> $<TARGET_OBJECTS:UTIL> $<TARGET_OBJECTS:MICROTAR>)\
target_link_libraries(osrm_guidance PRIVATE EXTRACTOR ${LUA_LIBRARIES} BZip2::BZip2 ZLIB::ZLIB EXPAT::EXPAT Boost::iostreams TBB::tbb)' CMakeLists.txt

    ### CMake flags
    LTO_FLAGS="-fno-lto"
    CMAKE_FLAGS+=(
        -DENABLE_LTO=OFF
        -DCMAKE_CXX_FLAGS="-Wno-array-bounds -Wno-uninitialized -Wno-unused-parameter -Wno-maybe-uninitialized ${LTO_FLAGS} -Wno-error -Wno-pedantic"
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
platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p) || Sys.iswindows(p), platforms)
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
    FileProduct("profiles/lib/pprint.lua", :lib_pprint_lua),
    FileProduct("profiles/lib/sequence.lua", :lib_sequence_lua),
    FileProduct("profiles/lib/traffic_signal.lua", :lib_traffic_signal_lua),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="=1.87.0"),
    Dependency("Lua_jll"; compat="~5.4.9"),
    Dependency("oneTBB_jll"; compat="2022.0.0"),
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("XML2_jll"; compat="~2.14.1"),
    Dependency("libzip_jll"),
    Dependency("Bzip2_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"13")
