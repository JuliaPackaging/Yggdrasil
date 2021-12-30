using BinaryBuilder


name = "DynarePreprocessor"
version = v"4.8.0-5"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "a8fce06dc46ca09329e6899e1fde47f2cd81809b"),
]

script = raw"""
if [[ ${target} == *-apple-* ]]
then
    sha="a8fce06dc46ca09329e6899e1fde47f2cd81809b"
    gitlabjob="37258"
    wget -O artifacts.zip https://git.dynare.org/Dynare/preprocessor/-/jobs/${gitlabjob}/artifacts/download
    mkdir work
    unzip artifacts.zip -d work
    tar zxf work/${sha}/macos-x86_64/dynare-preprocessor.tar.gz
    mkdir -p "${bindir}"
    cp dynare-preprocessor "${bindir}"
    install_license ${WORKSPACE}/srcdir/preprocessor/COPYING
else 
    apk add boost-dev
    apk add bison=3.7.6-r0 --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/main 
    apk add flex-dev

    cd ${WORKSPACE}/srcdir/preprocessor

    # remove -lstdc++fs in Makefile.am
    sed s/-lstdc++fs// -i src/Makefile.am

    autoreconf -si

    update_configure_scripts
    ./configure --prefix=$prefix  --build=${MACHTYPE} --host=${target} --disable-doc LDFLAGS="-static -static-libgcc -static-libstdc++"
    make -j${nproc}
    make install
    mkdir -p ../../destdir/bin
    if [[ ${target} == *-w64-* ]]; then
        strip src/dynare-preprocessor.exe
        cp src/dynare-preprocessor.exe ../../destdir/bin
    else
        strip src/dynare-preprocessor
        cp src/dynare-preprocessor ../../destdir/bin
    fi
fi
"""

platforms = [
    Platform("x86_64", "macOS"),
    Platform("x86_64", "Windows"),
    Platform("x86_64", "Linux")
]

products = [
    ExecutableProduct("dynare-preprocessor", Symbol("dynare_preprocessor")),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, preferred_gcc_version=v"10")

