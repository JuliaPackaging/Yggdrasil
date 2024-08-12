using BinaryBuilder, Pkg
using BinaryBuilderBase: default_host_platform

name = "DSSP"
version = v"4.4.0"

# url = "https://github.com/PDB-REDO/dssp"
# description = "Application to assign secondary structure to proteins"

sources = [
    GitSource("https://github.com/PDB-REDO/dssp",
              "c5ec1f2ddc800e7054d47a952b1ce21449f1d6b8"),
    GitSource("https://github.com/PDB-REDO/libcifpp",
              "836aed6ea9a227b37e5b0d9cbcb1253f545d0778"), # v5.1.0 (git-tag v5.1.0.1)
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    # Pre-compiled binaries for Windows
    FileSource("https://github.com/PDB-REDO/dssp/releases/download/v$(version)/mkdssp-$(version).exe",
               "fa897e3b23eaebf19878c7ba41180c7ce706d4333a528775e9daa047988b1cfe"),
    DirectorySource("./bundled"),
]

# NOTE
# On Windows we install pre-compiled binaries from github, as
# currently the executable built from source has a bug where it
# segfaults on any nontrivial operation.  This might be due to
# std::regex segfault issues for g++ mentioned in the libcifpp build
# instructions, so in the future it might be worthwile investigating
# compilation choices there.  The libcifpp cmake build tries to check
# for a std::regex segfault during build time, but this check has to
# be disabled here as we are cross-compiling.
#
# See also: https://github.com/PDB-REDO/dssp/issues/63

# NOTE
# We don't use libcifpp_jll, as linking to the shared library from
# libcifpp_jll currently fails on windows.  Instead, we build libcifpp
# here as a static library and use that to build dssp, as that seems
# to be the default way to build libcifpp and dssp.
#
# Run like this from julia:
#
# using DSSP_jll
# run(`$(DSSP_jll.mkdssp()) --mmcif-dictionary $(joinpath(DSSP_jll.artifact_dir, "share", "libcifpp", "mmcif_pdbx.dic")) 1aki.cif.gz`)


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
DSSP_VERSION=$version
""" * raw"""
cd $WORKSPACE/srcdir/

# Install pre-built binary on windows
if [[ "${target}" == *-w64-mingw* ]]; then
    apk add p7zip
    mkdir tmp-windows && cd tmp-windows
    7z x ../mkdssp-${DSSP_VERSION}.exe
    find bin/ -type f -exec install -Dvm 755 "{}" "${bindir}" \;
    find lib/ -type f -exec install -Dvm 755 "{}" "${prefix}/lib/" \;
    find include/ -type f -exec install -Dvm 644 "{}" "${includedir}" \;
    # needs zlib.dll library
    cp "${bindir}/libz.dll" "${bindir}/zlib.dll"
    # install mmcif dictionaries
    for dir in ../libcifpp/ ../dssp/; do
        find "${dir}" -type f -name '*.dic' -exec sh -c \
            'install -Dvm 644 "{}" "${prefix}/share/libcifpp/$(basename "{}")"' \;
    done
    install_license ../dssp/LICENSE
    exit 0
fi

# Install a newer MacOS SDK on x86_64-apple-darwin
# Fixes compilation of libcifpp and dssp
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

# build the tests if we are building for the build host platform
CFG_TESTING="-DENABLE_TESTING=OFF"
if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    CFG_TESTING="-DENABLE_TESTING=ON"
fi


###########
# libcifpp: install libcifpp static library
###########
cd libcifpp

# mingw doesn't have ioctl
# upstream PR: https://github.com/PDB-REDO/libcifpp/pull/45
atomic_patch -p1 ../patches/libcifpp-mingw-no-ioctl.patch

# fixes for clang and libc++ on macos for missing C++20 features
# (missing std::set::contains and operator<=>)
# Upstream issue: https://github.com/PDB-REDO/libcifpp/issues/39
if [[ "${target}" == *-apple-darwin* ]]; then
    atomic_patch -p1 ../patches/libcifpp-clang-libc++-fixes.patch
fi

mkdir build && cd build
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
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DBUILD_FOR_CCP4=OFF \
    -DCIFPP_DOWNLOAD_CCD=OFF \
    -DCIFPP_INSTALL_UPDATE_SCRIPT=OFF \
    -DBUILD_SHARED_LIBS=OFF \
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
cp ../LICENSE LICENSE-libcifpp
install_license LICENSE-libcifpp
cd ../..


###########
# dssp: now compile dssp
###########
cd dssp

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_FOR_CCP4=OFF \
    -DBUILD_WEBSERVER=OFF \
    ${CFG_TESTING}

make -j${nproc}
make install

# run dssp tests
if [[ "${bb_full_target}" == "${MACHTYPE_FULL}" ]]; then
    # run the tests on the build host platform
    make test
fi

install_license ../LICENSE
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("mkdssp", :mkdssp),
    FileProduct("share/libcifpp/dssp-extension.dic", :dssp_extension_dic),
    FileProduct("share/libcifpp/mmcif_ddl.dic", :mmcif_ddl_dic),
    FileProduct("share/libcifpp/mmcif_ma.dic", :mmcif_ma_dic),
    FileProduct("share/libcifpp/mmcif_pdbx.dic", :mmcif_pdbx_dic),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    BuildDependency("libmcfp_jll"),
    Dependency("Zlib_jll"),
    # boost is needed for `make test`, which we only run on `default_host_platform`
    HostBuildDependency("boost_jll"; platforms=[default_host_platform]),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"9")
