cd ${WORKSPACE}/srcdir/mkl-${target}
if [[ ${target} == *-mingw* ]]; then
    cp -r Library/bin/* ${libdir}
else
    cp -r lib/* ${libdir}
fi

install_license info/licenses/*.txt