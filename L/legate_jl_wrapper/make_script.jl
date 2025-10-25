function get_script(cuda::Val{true})
    script = raw"""

        # Put new CMake first on path
        export PATH=${host_bindir}:$PATH

        cd ${WORKSPACE}/srcdir/

        # Necessary operations to cross compile CUDA from x86_64 to aarch64
        if [[ "${target}" == aarch64-linux-* ]]; then

            # Add /usr/lib/csl-musl-x86_64 to LD_LIBRARY_PATH to be able to use host nvcc
            export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
            
            # Make sure we use host CUDA executable by copying from the x86_64 CUDA redist
            NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
            rm -rf ${prefix}/cuda/bin
            cp -r ${NVCC_DIR}/bin ${prefix}/cuda/bin
            
            rm -rf ${prefix}/cuda/nvvm/bin
            cp -r ${NVCC_DIR}/nvvm/bin ${prefix}/cuda/nvvm/bin

            export NVCC_PREPEND_FLAGS="-ccbin='${CXX}'"
        fi

        export CUDA_HOME=${prefix}/cuda;
        export PATH=$PATH:$CUDA_HOME/bin
        export CUDACXX=$CUDA_HOME/bin/nvcc
        export CUDA_LIB=${CUDA_HOME}/lib

        ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

        mkdir build
        cd build
        cmake \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_FIND_ROOT_PATH=${prefix} \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DJulia_PREFIX=${prefix} \
            ../legate_jl_wrapper/

        VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
        install_license $WORKSPACE/srcdir/legate_jl_wrapper*/LICENSE
    """
    return script
end

function get_script(cuda::Val{false})
    script = raw"""

        # Put new CMake first on path
        export PATH=${host_bindir}:$PATH

        cd ${WORKSPACE}/srcdir/

        mkdir build
        cd build
        cmake \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_FIND_ROOT_PATH=${prefix} \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DJulia_PREFIX=${prefix} \
            ../legate_jl_wrapper/

        VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
        install_license $WORKSPACE/srcdir/legate_jl_wrapper*/LICENSE
    """
    return script
end
