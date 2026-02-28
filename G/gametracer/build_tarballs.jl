using BinaryBuilder

name = "gametracer"
version = v"0.2.1"

const GIT_SHA = "49ba14e396ddc21fbcd54621e610d355b7106c5e"

sources = [
    GitSource("https://github.com/QuantEcon/gametracer.git", GIT_SHA),
]

script = raw"""
set -euxo pipefail

cd "${WORKSPACE}/srcdir/gametracer"

# Sanity-check that the c_api entry-point exists at the expected location
test -d c_api
test -f c_api/CMakeLists.txt

cmake -S c_api -B build \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${prefix}"

cmake --build build --parallel "${nproc}"
cmake --install build

# Verify the shared library was installed
if [[ ! -f "${libdir}/libgametracer.${dlext}" ]]; then
    echo "ERROR: libgametracer.${dlext} not found under ${libdir}"
    find "${prefix}" -maxdepth 6 -name "libgametracer.*" || true
    exit 1
fi

# Verify the license file was installed (Yggdrasil audit requirement)
if [[ ! -f "${prefix}/share/licenses/gametracer/COPYING" ]]; then
    echo "ERROR: missing license file: ${prefix}/share/licenses/gametracer/COPYING"
    find "${prefix}/share" -maxdepth 7 -name "COPYING" -o -name "LICENSE*" || true
    exit 1
fi
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libgametracer", :libgametracer),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")
