using BinaryBuilder, Pkg
using BinaryBuilderBase: default_host_platform

name = "libcifpp"
version = v"5.1.0"

# url = "https://github.com/PDB-REDO/libcifpp"
# description = "Library containing code to manipulate mmCIF and PDB files"

sources = [
    GitSource("https://github.com/PDB-REDO/libcifpp",
              "836aed6ea9a227b37e5b0d9cbcb1253f545d0778"),
    DirectorySource("./bundled"),
]

# TODO
# - the installed file etc/cron.weekly/update-libcifpp-data contains
#   hardcoded paths with /workspace/destdir/...
#   It is used to update components.cif, which should probably be done
#   in a different way.
#
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

# Note: test suite (`make test`) is run if we are building for the
# build host platform BinaryBuilderBase.default_host_platform, which
# is the case for `$target == $MACHTYPE` inside the shell script.

# Note: cmake cache vars are set sometimes because we are
# cross-compiling, normally cmake would try and run a program to
# determine if a feature is available.
#
# -DSTD_REGEX_RUNNING=0               # std::regex works
# -D_CXX_ATOMIC_BUILTIN_EXITCODE=0    # std::atomic works
# -D_CXX_ATOMIC_BUILTIN_EXITCODE__TRYRUN_OUTPUT=0

script = raw"""
cd $WORKSPACE/srcdir/libcifpp*/

# mingw doesn't have ioctl
atomic_patch -p1 ../patches/mingw-no-ioctl.patch

mkdir build && cd build

CFG_TESTING="-DENABLE_TESTING=OFF"
if [[ "${target}" == "${MACHTYPE}" ]]; then
    # build the tests if we are building for the build host platform
    CFG_TESTING="-DENABLE_TESTING=ON"
fi

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCIFPP_DOWNLOAD_CCD=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DSTD_REGEX_RUNNING=OFF \
    -D_CXX_ATOMIC_BUILTIN_EXITCODE=0 \
    -D_CXX_ATOMIC_BUILTIN_EXITCODE__TRYRUN_OUTPUT=0 \
    ${CFG_TESTING}

make -j${nproc}

if [[ "${target}" == "${MACHTYPE}" ]]; then
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
