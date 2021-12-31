using BinaryBuilder


name = "DynarePreprocessor"
version = v"4.8.0"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "a8fce06dc46ca09329e6899e1fde47f2cd81809b"),
]

script = raw"""
HostBuildDependency("boost_jll")
HostBuildDependency("Bison_jll")
HostBuildDependency("flex_jll")

cd ${WORKSPACE}/srcdir/preprocessor

# remove -lstdc++fs in Makefile.am
sed s/-lstdc++fs// -i src/Makefile.am

autoreconf -si

# use non default gcc for apple and freebsdn
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi

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
    ExecutableProduct("dynare-preprocessor", Symbol("dynare_preprocessor")),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, preferred_gcc_version=v"10")

