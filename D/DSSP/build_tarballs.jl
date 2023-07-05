using BinaryBuilder, Pkg
using BinaryBuilderBase: default_host_platform

name = "DSSP"
version = v"4.3.1"

# url = "https://github.com/PDB-REDO/dssp"
# description = "Application to assign secondary structure to proteins"

sources = [
    GitSource("https://github.com/PDB-REDO/dssp",
              "b87ef206a071e6f086c8dc01551afd5e9b23eb43"),
    GitSource("https://github.com/mhekkel/libmcfp",
              "4aa95505ded43e663fd9dae61c49b08fdc6cce0c"), # v1.2.4
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled"),
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
cd $WORKSPACE/srcdir/

# Install a newer MacOS SDK
# fixes compilation of dssp
# - cmake fails on checking for std::filesystem
# - compile error: 'any_cast<std::basic_string<char>>' is unavailable: introduced in macOS 10.14
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi


# install header-only libmcfp command-line argument parser
cd libmcfp
mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
cp ../LICENSE LICENSE-libmcfp
install_license LICENSE-libmcfp
cd ../..


# now compile dssp proper
cd dssp

# fix libcifpp linkage
# Ref: https://github.com/PDB-REDO/dssp/commit/49306a57098f1eaebb700eed29025e6f472a799a
atomic_patch -p1 ../patches/cmake-fix-libcifpp-linkage.patch

CFG_TESTING="-DENABLE_TESTING=OFF"
if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    # build the tests if we are building for the build host platform
    CFG_TESTING="-DENABLE_TESTING=ON"
fi

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

# build and install shared library libdssp
"${CXX}" -shared -o "${libdir}/libdssp.${dlext}" \
    -Wl,$(flagon --whole-archive) "${libdir}/libdssp.a" -Wl,$(flagon --no-whole-archive) \
    -lcifpp

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
