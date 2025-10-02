using BinaryBuilder

name = "DynarePreprocessor"
version = v"7.0.0"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "e4ba46115a6d896b1cdec043bd5612628f7c43a5"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/preprocessor

# Use flex from `flex_jll` instead of the one under /usr/bin,
# because there is no /usr/include/FlexLexer.hh
echo -e "[binaries]\nflex = '${host_bindir}/flex'\n" > flex.ini

# We enforce GCC on all platforms (i.e. incl. macOS and FreeBSD), by using the GCC toolchain file
# See https://docs.binarybuilder.org/stable/build_tips/#Using-GCC-on-macOS-and-FreeBSD
meson setup --cross-file="${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson" --cross-file=flex.ini --buildtype=release build

ninja -j${nproc} -v -C build
ninja -C build install

strip "${bindir}/dynare-preprocessor${exeext}"

install_license COPYING
"""

platforms = expand_cxxstring_abis(supported_platforms(); skip=Returns(false))

products = [
    ExecutableProduct("dynare-preprocessor", :dynare_preprocessor),
]

dependencies = [
    BuildDependency("boost_jll"),
    HostBuildDependency("flex_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")
