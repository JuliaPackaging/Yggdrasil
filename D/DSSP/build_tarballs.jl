using BinaryBuilder, Pkg
using BinaryBuilderBase: default_host_platform

name = "DSSP"
version = v"4.3.1"

# url = "https://github.com/PDB-REDO/dssp"
# description = "Application to assign secondary structure to proteins"

sources = [
    GitSource("https://github.com/PDB-REDO/dssp",
              "b87ef206a071e6f086c8dc01551afd5e9b23eb43"),
]

# The tests only pass with the correct cxxabi (-cxx11), so we create a
# MACHTYPE_FULL variable to pass to the shell script which can there
# be matched against to bb_full_target.
#
# TODO: can we get the "libgfortran5" from default_host_platform?
#
# Convert x86_64-linux-musl-cxx11 -> x86_64-linux-musl-libgfortran5-cxx11
const M = split(triplet(default_host_platform), "-")
const MACHTYPE_FULL = join((M[1:3]..., "libgfortran5", M[4:end]...), "-")

script = """
MACHTYPE_FULL=$MACHTYPE_FULL
""" * raw"""
cd $WORKSPACE/srcdir/dssp*/


CFG_TESTING="-DENABLE_TESTING=OFF"
if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    # build the tests if we are building for the build host platform
    CFG_TESTING="-DENABLE_TESTING=ON"
fi

# install header-only libmcfp command-line argument parser
git clone --depth 1 --branch v1.2.4 https://github.com/mhekkel/libmcfp
cd libmcfp
mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
cd ../..

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_FOR_CCP4=OFF \
    -DBUILD_WEBSERVER=OFF \
    -DCMAKE_CXX_FLAGS="-fPIC" \
    ${CFG_TESTING}

make -j${nproc}

if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    # run the tests on the build host platform
    make test
fi

make install

# build shared library
"${CC}" -shared -o "${libdir}/libdssp.${dlext}" \
    -Wl,$(flagon --whole-archive) "${libdir}/libdssp.a" -Wl,$(flagon --no-whole-archive)

install_license ../LICENSE
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("mkdssp", :mkdssp),
    LibraryProduct("libdssp", :libdssp),
    FileProduct("lib/libdssp.a", :libdssp_a),
]

dependencies = [
    Dependency("Zlib_jll"),
    Dependency("libcifpp_jll"),
    # needed for make test, which we only run on the `default_host_platform`
    HostBuildDependency("boost_jll"; platforms=[default_host_platform]),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"10")
