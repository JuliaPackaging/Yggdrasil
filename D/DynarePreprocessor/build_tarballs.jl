using BinaryBuilder


name = "DynarePreprocessor"
version = v"6.0.2"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "00fd9dadb6dde5929c224c74e0a43715554a2c05"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/preprocessor

# remove -lstdc++fs in Makefile.am
sed s/-lstdc++fs// -i src/Makefile.am

# Remove flex from RootFS to let use our flex from `flex_jll`
rm -f /usr/bin/flex

autoreconf -si

update_configure_scripts
./configure --prefix=$prefix  --build=${MACHTYPE} --host=${target} --disable-doc
make -j${nproc}
make install
mkdir -p "${bindir}"
strip "src/dynare-preprocessor${exeext}"
cp "src/dynare-preprocessor${exeext}" "${bindir}"
install_license COPYING
"""

platforms = expand_cxxstring_abis(supported_platforms(exclude=[Platform("aarch64", "macOS"), Platform("x86_64", "macOS"), Platform("x86_64", "FreeBSD")]) )

products = [
    ExecutableProduct("dynare-preprocessor", :dynare_preprocessor),
]

dependencies = [
    BuildDependency("boost_jll"),
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("flex_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")
