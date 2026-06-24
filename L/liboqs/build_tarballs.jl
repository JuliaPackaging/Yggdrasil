using BinaryBuilder, Pkg

name = "liboqs"
version = v"0.14.0"

sources = [
    GitSource(
        "https://github.com/open-quantum-safe/liboqs.git",
        "94b421ebb82405c843dba4e9aa521a56ee5a333d",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/liboqs
install_license LICENSE.txt

# The project’s helper CMake files inject -march/-mcpu/-mtune. In cross builds these
# override the CPU/ABI chosen by the toolchain and can select unsupported ISAs or break
# assembly. The cross toolchain should be the sole source of ISA/ABI flags, so strip them.
LC_ALL=C sed -i.bak -E 's/-march=[^" )]+//g; s/-mcpu=[^" )]+//g; s/-mtune=[^" )]+//g' .CMake/*.cmake cmake/*.cmake 2>/dev/null || true

EXTRA_FLAGS=()
if [[ ${target} == *arm-linux* ]]; then
  EXTRA_FLAGS+=(-DOQS_PERMIT_UNSUPPORTED_ARCHITECTURE=ON)
fi

if [[ ${target} == *aarch64-apple* ]]; then
  # Avoid getting errors like: error: instruction requires: sha3
  EXTRA_FLAGS+=(-DOQS_DIST_BUILD=OFF)
fi

if [[ ${target} == *aarch64-linux* ]]; then
  # Disable AES-NI optimizations to avoid target specific option mismatch
  EXTRA_FLAGS+=(-DOQS_DIST_BUILD=OFF)
  EXTRA_FLAGS+=(-DOQS_USE_AES_INSTRUCTIONS=OFF)
fi

cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DOQS_USE_OPENSSL=OFF \
  -DBUILD_SHARED_LIBS=ON \
  -DOQS_BUILD_ONLY_LIB=ON \
  -DCMAKE_BUILD_TYPE=Release \
  "${EXTRA_FLAGS[@]}"

cmake --build build --parallel ${nproc}
cmake --install build
"""

products = [LibraryProduct("liboqs", :liboqs)]

platforms = supported_platforms()

dependencies = Dependency[]

# preferred_gcc_version=v"11" is required to build on Platform("aarch64", "linux"; libc = "musl")
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.10", preferred_gcc_version=v"11")
