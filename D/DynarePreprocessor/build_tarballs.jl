using BinaryBuilder


name = "DynarePreprocessor"
version = v"4.8.0-5"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "a8fce06dc46ca09329e6899e1fde47f2cd81809b"),
]

script = raw"""
apk add boost-dev
apk add bison=3.7.6-r0 --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/main 
apk add flex-dev

cd ${WORKSPACE}/srcdir/preprocessor

# remove -lstdc++fs in Makefile.am
sed s/-lstdc++fs// -i src/Makefile.am
# don't use gnu extensions
sed s/STDCXX_17/STDCXX(17, noext)/ -i configure.ac

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
    ExecutableProduct("dynare-preprocessor", Symbol("dynare_preprocessor")),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, preferred_gcc_version=v"10")

