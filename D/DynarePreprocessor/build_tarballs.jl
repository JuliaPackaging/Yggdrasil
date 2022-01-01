using BinaryBuilder


name = "DynarePreprocessor"
version = v"4.8.0"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "a8fce06dc46ca09329e6899e1fde47f2cd81809b"),
    DirectorySource("./bundled")
]

script = raw"""
cd ${WORKSPACE}/srcdir/preprocessor

# remove -lstdc++fs in Makefile.am
sed s/-lstdc++fs// -i src/Makefile.am

# Remove flex from RootFS to let use our flex from `flex_jll`
rm -f /usr/bin/flex

# Help FreeBSD find header files.  See
# https://github.com/JuliaPackaging/Yggdrasil/issues/3949
if [[ "${target}" == *-freebsd* ]]; then
    export CPPFLAGS="-I${includedir}"
fi

atomic_patch -p1 "../patches/patches.patch"

autoreconf -si

update_configure_scripts
./configure --prefix=$prefix  --build=${MACHTYPE} --host=${target} --disable-doc
make -j${nproc}
make install
mkdir -p "${bindir}"
strip "src/dynare-preprocessor${exeext}"
cp "src/dynare-preprocessor${exeext}" "${bindir}"
"""

platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

products = [
    ExecutableProduct("dynare-preprocessor", :dynare_preprocessor),
]

dependencies = [
    BuildDependency("boost_jll"),
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("flex_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
