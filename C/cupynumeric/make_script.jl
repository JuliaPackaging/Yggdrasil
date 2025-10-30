function get_script(cuda::Val{true})
    script = raw"""

        # Build crashes without this
        export TMPDIR=${WORKSPACE}/tmpdir
        mkdir -p ${TMPDIR}

        # Copy cuTensor archive to proper dirs
        cd ${WORKSPACE}/srcdir
        cp -a ./include/. ${includedir}
        cp -a ./lib/. ${libdir}

        # Put new CMake first on path
        export PATH=${host_bindir}:$PATH

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

        ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

        ## BUILD TBLIS ##
        cd ${WORKSPACE}/srcdir/tblis

        for i in ./Makefile.* ./configure*; do

            # Building in container forbids -march options
            sed -i "s/-march[^ ]*//g" $i

        done

        case ${target} in
            *"x86_64"*"linux"*"gnu"*) 
                export BLI_CONFIG=x86,reference
                ;;
            *"aarch64"*)
                ;;
            *)
                ;;
        esac

        ./configure \
            --prefix=$prefix \
            --build=${MACHTYPE} \
            --host=${target} \
            --with-label-type=int32_t \
            --with-length-type=int64_t \
            --with-stride-type=int64_t \
            --enable-thread-model=openmp \
            --enable-config=${BLI_CONFIG}

        make -j ${nproc} && make install

        cd ${WORKSPACE}/srcdir/cupynumeric

        mkdir build
        cmake -S . -B build \
            -Dlegate_ROOT:STRING=${prefix} \
            -DCMAKE_PREFIX_PATH=${prefix} \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_BUILD_TYPE=Release \
            -DNCCL_LIBRARY=${libdir}/libnccl.so \
            -DNCCL_INCLUDE_DIR=${includedir} \
            -Dcutensor_LIBRARY=${libdir}/libcutensor.so \
            -Dcutensor_INCLUDE_DIR=${includedir} \
            -DBLAS_LIBRARIES=${libdir}/libopenblas.so \

        cmake --build build --parallel ${nproc} --verbose
        cmake --install build

        install_license $WORKSPACE/srcdir/cupynumeric*/LICENSE
        install_license $WORKSPACE/srcdir/share/licenses/CUTENSOR/LICENSE
    """

    return script
end

function get_script(cuda::Val{false})
        script = raw"""

        # Build crashes without this
        export TMPDIR=${WORKSPACE}/tmpdir
        mkdir -p ${TMPDIR}

        # Put new CMake first on path
        export PATH=${host_bindir}:$PATH

        ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

        ## BUILD TBLIS ##
        cd ${WORKSPACE}/srcdir/tblis

        for i in ./Makefile.* ./configure*; do

            # Building in container forbids -march options
            sed -i "s/-march[^ ]*//g" $i

        done

        case ${target} in
            *"x86_64"*"linux"*"gnu"*) 
                export BLI_CONFIG=x86,reference
                ;;
            *"aarch64"*)
                ;;
            *)
                ;;
        esac

        ./configure \
            --prefix=$prefix \
            --build=${MACHTYPE} \
            --host=${target} \
            --with-label-type=int32_t \
            --with-length-type=int64_t \
            --with-stride-type=int64_t \
            --enable-thread-model=openmp \
            --enable-config=${BLI_CONFIG}

        make -j ${nproc} && make install

        cd ${WORKSPACE}/srcdir/cupynumeric

        mkdir build
        cmake -S . -B build \
            -Dlegate_ROOT:STRING=${prefix} \
            -DCMAKE_PREFIX_PATH=${prefix} \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_BUILD_TYPE=Release \
            -DBLAS_LIBRARIES=${libdir}/libopenblas.so \

        cmake --build build --parallel ${nproc} --verbose
        cmake --install build

        install_license $WORKSPACE/srcdir/cupynumeric*/LICENSE
    """

    return script
end
