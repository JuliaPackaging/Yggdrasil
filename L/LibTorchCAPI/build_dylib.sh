#!/bin/bash

OS=$(uname)
case $OS in
MINGW*)
  OS="windows"
  ;;
*)
  OS=$(echo $OS | tr '[:upper:]' '[:lower:]')
  ;;
esac

# target=x86_64-linux-gnu
cd $WORKSPACE/srcdir

PROJECT_DIR=$WORKSPACE/srcdir/ThArrays.jl

RELEASES=(
    x86_64-linux-gnu@v1_7_1@https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-1.7.1%2Bcpu.zip
    x86_64-apple-darwin14@v1_7_1@https://download.pytorch.org/libtorch/cpu/libtorch-macos-1.7.1.zip
    x86_64-w64-mingw32@v1_7_1@https://download.pytorch.org/libtorch/cpu/libtorch-win-shared-with-deps-1.7.1.zip
)

for RELEASE in ${RELEASES[@]}; do
    REL_TARGET=$(echo $RELEASE | cut -d@ -f1)
    if [ $target != $REL_TARGET ]; then
        continue
    fi

    # prepare libtorch
    rm -f *.zip
    rm -fr libtorch/
    wget $(echo $RELEASE | cut -d@ -f3)
    unzip *.zip
    LIBTORCH_PATH=$PWD/libtorch

    # build capi
    mkdir -p ${PROJECT_DIR}/csrc/build
    cd ${PROJECT_DIR}/csrc/build
    cmake -DCMAKE_PREFIX_PATH=${LIBTORCH_PATH} ..
    make torch_capi

    mkdir -p ${libdir}
    if [[ $OS == "darwin" ]]; then
        # copy libs
        cp ${PROJECT_DIR}/csrc/build/libtorch_capi.dylib ${libdir}/
        cp ${LIBTORCH_PATH}/lib/libtorch.dylib ${libdir}/
        cp ${LIBTORCH_PATH}/lib/libc10.dylib ${libdir}/
        cp ${LIBTORCH_PATH}/lib/libiomp5.dylib ${libdir}/

        # patch dylib
        install_name_tool -change  @rpath/libtorch.dylib @loader_path/libtorch.dylib ${libdir}/libtorch_capi.dylib
        install_name_tool -change  @rpath/libtorch_cpu.dylib @loader_path/libtorch_cpu.dylib ${libdir}/libtorch_capi.dylib
        install_name_tool -change  @rpath/libc10.dylib @loader_path/libc10.dylib ${libdir}/libtorch_capi.dylib

        install_name_tool -change  @rpath/libtorch_cpu.dylib @loader_path/libtorch_cpu.dylib ${libdir}/libtorch.dylib
        install_name_tool -change  @rpath/libc10.dylib @loader_path/libc10.dylib ${libdir}/libtorch.dylib
        install_name_tool -change  @rpath/libiomp5.dylib @loader_path/libiomp5.dylib ${libdir}/libtorch.dylib
        install_name_tool -change  @rpath/libiomp5.dylib @loader_path/libiomp5.dylib ${libdir}/libtorch_cpu.dylib
    elif [[ $OS == "linux" ]]; then
        # copy libs
        cp ${PROJECT_DIR}/csrc/build/libtorch_capi.so ${libdir}/
        cp ${LIBTORCH_PATH}/lib/libtorch.so ${libdir}/
        cp ${LIBTORCH_PATH}/lib/libtorch_cpu.so ${libdir}/
        cp ${LIBTORCH_PATH}/lib/libc10.so ${libdir}/
        cp ${LIBTORCH_PATH}/lib/libgomp-75eea7e8.so.1 ${libdir}/

        # patch dylib
        patchelf --replace-needed "libtorch.so" "\$ORIGIN/libtorch.so" ${libdir}/libtorch_capi.so
        patchelf --replace-needed "libtorch_cpu.so" "\$ORIGIN/libtorch_cpu.so" ${libdir}/libtorch_capi.so
        patchelf --replace-needed "libc10.so" "\$ORIGIN/libc10.so" ${libdir}/libtorch_capi.so
    fi
done

install_license $PROJECT_DIR/LICENSE
