script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == *-linux-gnu ]]; then
    cd libcutensor*
    find .

    install_license LICENSE

    mv lib/11/libcutensor.so* ${libdir}
    mv lib/11/libcutensorMg.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd libcutensor*
    find .

    install_license LICENSE

    mv lib/11/cutensor.dll ${libdir}
    mv lib/11/cutensorMg.dll ${libdir}
    mv include/* ${prefix}/include

    # fixup
    chmod +x ${libdir}/*.dll
fi
"""
