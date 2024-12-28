using BinaryBuilder, Pkg
using BinaryBuilderBase: default_host_platform

name = "libcifpp"
version = v"5.1.1"

# url = "https://github.com/PDB-REDO/libcifpp"
# description = "Library containing code to manipulate mmCIF and PDB files"

sources = [
    GitSource("https://github.com/PDB-REDO/libcifpp",
              "15a49f1bb4f555ea11a9186015df28adf7a10cb0"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled"),
]

# TODO
# - the CCD (chemical components dictionary) normally gets downloaded
#   by default and saved under share/libcifpp/components.cif, but we
#   don't do this
#
#   This file is quite large (88MB gzipped, 380MB decompressed as of
#   July 2023). Therefore, download and installation of this file is
#   disabled for now, but not sure what functionality is impacted by
#   this. We should maybe think of a better way of sharing
#   components.cif between different packages that need it.
#   Ref: https://www.wwpdb.org/data/ccd

# Note: we use a newer MacOS SDK to compile on x86_64-apple-darwin
# fixes missing `shared_timed_mutex` and linking problems for
# std::filesystem

# Note: upstream seems to recommend gcc >= 10
#       https://github.com/PDB-REDO/libcifpp/issues/39

# Note: test suite (`make test`) is run if we are building for the
# build host platform BinaryBuilderBase.default_host_platform, which
# is the case for `$target == $MACHTYPE` inside the shell script.
#
# The tests only pass with the correct cxxabi (-cxx11), so we create a
# MACHTYPE_FULL variable to pass to the shell script which can there
# be matched against to bb_full_target.
#
# TODO: can we get the "libgfortran5" from default_host_platform?
#
# Convert x86_64-linux-musl-cxx11 -> x86_64-linux-musl-libgfortran5-cxx11
const M = split(triplet(default_host_platform), "-")
const MACHTYPE_FULL = join((M[1:3]..., "libgfortran5", M[4:end]...), "-")

script =
"""
MACHTYPE_FULL=$MACHTYPE_FULL
""" * raw"""
cd $WORKSPACE/srcdir/libcifpp*/

# fix windows header include
# upstream PR: https://github.com/PDB-REDO/libcifpp/pull/45
# parts of the PR have already been merged upstream
atomic_patch -p1 ../patches/mingw-fix-windows-include.patch

# fix windows mingw undefined symbols
atomic_patch -p1 ../patches/mingw-fix-undefined-symbols.patch

# fixes for clang and libc++ on macos for missing C++20 features
# (missing std::set::contains and operator<=>)
# Upstream issue: https://github.com/PDB-REDO/libcifpp/issues/39
if [[ "${target}" == *-apple-darwin* ]]; then
    atomic_patch -p1 ../patches/clang-libc++-fixes.patch
fi

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `shared_timed_mutex` and `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi


mkdir build && cd build

CFG_TESTING="-DENABLE_TESTING=OFF"
if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    # build the tests if we are building for the build host platform
    CFG_TESTING="-DENABLE_TESTING=ON"
fi

# Set cmake cache vars because test programs can't be run during
# cross-compilation
#
# -DSTD_REGEX_RUNNING=0               # std::regex works
# -D_CXX_ATOMIC_BUILTIN_EXITCODE=0    # std::atomic works
# -D_CXX_ATOMIC_BUILTIN_EXITCODE__TRYRUN_OUTPUT=0
#
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_FOR_CCP4=OFF \
    -DCIFPP_DOWNLOAD_CCD=OFF \
    -DCIFPP_INSTALL_UPDATE_SCRIPT=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DSTD_REGEX_RUNNING=OFF \
    -D_CXX_ATOMIC_BUILTIN_EXITCODE=0 \
    -D_CXX_ATOMIC_BUILTIN_EXITCODE__TRYRUN_OUTPUT=0 \
    ${CFG_TESTING}

make -j${nproc}

if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    # run the tests on the build host platform
    make test
fi

make install

install_license ../LICENSE
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libcifpp", :libcifpp),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    Dependency("Zlib_jll"),
    # needed for make test, which we only run on the `default_host_platform`
    HostBuildDependency("boost_jll"; platforms=[default_host_platform]),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"9")
