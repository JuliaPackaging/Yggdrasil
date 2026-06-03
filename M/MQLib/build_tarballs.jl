# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MQLib"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/MQLib/MQLib.git",
        "585496274af5abb0849d0d47e135496b4688680b",
    ),
    GitSource(
        "https://github.com/JuliaQUBO/MQLib.jl.git",
        "3160500db96ca1a1bb1271897c4141b9124676cf",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd "${WORKSPACE}/srcdir"

MQLIB_SRC="${WORKSPACE}/srcdir/MQLib"
MQLIB_C_HEADER="$(find "${WORKSPACE}/srcdir" -path '*/c_api/include/mqlib_c_api.h' -print -quit)"
MQLIB_JL_SRC="${MQLIB_C_HEADER%/c_api/include/mqlib_c_api.h}"

if [[ ! -f "${MQLIB_JL_SRC}/c_api/src/mqlib_c_api.cpp" ]]; then
    echo "Could not find MQLib.jl C ABI sources" >&2
    exit 1
fi

mkdir -p "${bindir}" "${libdir}" "${includedir}" "${datadir}/mqlib/hhdata"

cd "${MQLIB_SRC}"
make -j${nproc}
install -Dvm 0755 bin/MQLib "${bindir}/MQLib${exeext}"
install -Dvm 0644 \
    "${MQLIB_JL_SRC}/c_api/include/mqlib_c_api.h" \
    "${includedir}/mqlib_c_api.h"
install -vm 0644 hhdata/*.rf "${datadir}/mqlib/hhdata/"

MQLIB_LIBRARY_SOURCES="$(find src -name '*.cpp' ! -name main.cpp | sort)"

if [[ "${target}" == *-mingw* ]]; then
    MQLIB_C_API_SHARED_FLAGS=(
        -shared
        -Wl,--out-implib,"${libdir}/libmqlib_c_api.dll.a"
    )
elif [[ "${target}" == *-apple-darwin* ]]; then
    MQLIB_C_API_SHARED_FLAGS=(
        -dynamiclib
        -Wl,-install_name,@rpath/libmqlib_c_api.${dlext}
    )
else
    MQLIB_C_API_SHARED_FLAGS=(-shared)
fi
MQLIB_C_API_LIBRARY="${libdir}/libmqlib_c_api.${dlext}"

"${CXX}" \
    -std=c++11 \
    -O2 \
    -fPIC \
    -DMQLIB_C_BUILD_SHARED \
    -Iinclude \
    -I"${MQLIB_JL_SRC}/c_api/include" \
    ${MQLIB_LIBRARY_SOURCES} \
    "${MQLIB_JL_SRC}/c_api/src/mqlib_c_api.cpp" \
    "${MQLIB_C_API_SHARED_FLAGS[@]}" \
    -o "${MQLIB_C_API_LIBRARY}" \
    -lm
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    ExecutableProduct("MQLib", :MQLib),
    LibraryProduct("libmqlib_c_api", :libmqlib_c_api),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
