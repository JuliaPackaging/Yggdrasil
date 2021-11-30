# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg, Base.BinaryPlatforms

name = "xtrx"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xtrx-sdr/libxtrxdsp", "eec28640c0ebd5639b642f07b310a0a0d02d9834"),
    GitSource("https://github.com/xtrx-sdr/libxtrxll", "1b6eddfbedc700efb6f7e3c3594e43ac6ff29ea4"),
    GitSource("https://github.com/xtrx-sdr/libxtrx", "acb0b1cf7ab92744034767a04c1d4b4c281b840f"),
    GitSource("https://github.com/xtrx-sdr/liblms7002m", "b07761b7386181f0e6a35158456b75bce14f2aca"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""

# Apply our patches
cd ${WORKSPACE}/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# liblms7002m requires python3 and cheetah to perform build-time templating
apk add python3 py3-cheetah

if [[ ${bb_target} == x86_64-* ]] || [[ ${bb_target} == i686-* ]]; then
    XTRX_ARCH=x86
elif [[ ${bb_target} == aarch64-* ]] || [[ ${bb_target} == arm* ]]; then
    XTRX_ARCH=arm
fi

CMAKE_ARGS=(
    "-DCMAKE_INSTALL_PREFIX=${prefix}"
    "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"
    "-DCMAKE_BUILD_TYPE=Release"

    # CC_ARCH isn't set properly; just override
    "-DFORCE_ARCH=${XTRX_ARCH}"

    # Install utilities to `bin`
    "-DXTRXDSP_UTILS_DIR=${bindir}"
    "-DXTRXLL_UTILS_DIR=${bindir}"
)

mkdir ${WORKSPACE}/srcdir/liblms7002m_build
cd ${WORKSPACE}/srcdir/liblms7002m_build
cmake ${CMAKE_ARGS[@]} ${WORKSPACE}/srcdir/liblms7002m
make -j${nproc}
make install

mkdir ${WORKSPACE}/srcdir/libxtrxdsp_build
cd ${WORKSPACE}/srcdir/libxtrxdsp_build
cmake ${CMAKE_ARGS[@]} ${WORKSPACE}/srcdir/libxtrxdsp
make -j${nproc}
make install

mkdir ${WORKSPACE}/srcdir/libxtrxll_build
cd ${WORKSPACE}/srcdir/libxtrxll_build
cmake ${CMAKE_ARGS[@]} -DENABLE_PCIE=ON ${WORKSPACE}/srcdir/libxtrxll
make -j${nproc}
make install

mkdir ${WORKSPACE}/srcdir/libxtrx_build
cd ${WORKSPACE}/srcdir/libxtrx_build
cmake ${CMAKE_ARGS[@]} ${WORKSPACE}/srcdir/libxtrx
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/libxtrx/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# Disable everything except glibc Linux for now, and only intel/arm processors
filter!(p -> Sys.islinux(p) && libc(p) == "glibc" && proc_family(p) ∈ ("intel", "arm"), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("test_xtrxll", :test_xtrxll),
    ExecutableProduct("test_xtrxflash", :test_xtrxflash),
    ExecutableProduct("test_xtrx", :test_xtrx),
    LibraryProduct("libxtrx", :libxtrx),
    LibraryProduct("libxtrxll", :libxtrxll),
    LibraryProduct("libxtrxdsp", :libxtrxdsp),
    LibraryProduct("liblms7compact", :liblms7compact),
    LibraryProduct("libXTRXSupport", :libXTRXSupport, ["lib/SoapySDR/modules0.8"]),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("soapysdr_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
