script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == *-linux-gnu ]]; then
    cd libcutensor
    find .

    install_license license.txt

    mv lib/11.0/libcutensor.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd libcutensor
    find .

    install_license license.txt

    mv lib/11.0/cutensor.dll ${libdir}
    mv include/* ${prefix}/include

    # fixup
    chmod +x ${libdir}/*.{exe,dll}
fi
"""
