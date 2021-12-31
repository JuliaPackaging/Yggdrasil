using BinaryBuilder


name = "DynarePreprocessor"
version = v"4.8.0"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "a8fce06dc46ca09329e6899e1fde47f2cd81809b"),
    DirectorySource("./bundled")
]

script = raw"""

apk add boost-dev

cd ${WORKSPACE}/srcdir/preprocessor

# remove -lstdc++fs in Makefile.am
sed s/-lstdc++fs// -i src/Makefile.am

atomic_patch -p1 "../patches/equationstags.patch"

autoreconf -si

update_configure_scripts
./configure --prefix=$prefix  --build=${MACHTYPE} --host=${target} --disable-doc
make -j${nproc}
make install
mkdir -p "${bindir}"
strip "src/dynare-preprocessor${exeext}"
cp "src/dynare-preprocessor${exeext}" "${bindir}"
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("dynare-preprocessor", :dynare_preprocessor),
]

dependencies = [
HostBuildDependency("Bison_jll"),
HostBuildDependency("flex_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, preferred_gcc_version=v"10")

