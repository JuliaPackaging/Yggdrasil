
function get_script(cuda::Val{true})
    script = raw"""

    # We will build with clang
    export CC="clang"
    export CXX="clang++"
    export BUILD_CXX=$(which clang++)
    export BUILD_CC=$(which clang)

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

    # Put new CMake first on path
    export PATH=${host_bindir}:$PATH

    # Install Python 3.11 (via miniconda)
    cd ${WORKSPACE}/srcdir
    bash miniconda.sh -b -p ${host_bindir}/miniconda

    # Create venv and install configure script dependencies
    ${host_bindir}/miniconda/bin/python -m venv ./venv
    source ./venv/bin/activate
    pip install --upgrade pip
    pip install rich typing_extensions packaging

    python -c "import rich, typing_extensions, packaging; print('Python deps installed and working!')"

    cd ${WORKSPACE}/srcdir/legate

    ### Set Up CUDA ENV Vars

    export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
    export CFLAGS="${CFLAGS} -I${prefix}/include"
    export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"

    export CUDA_HOME=${prefix}/cuda;
    export PATH=$PATH:$CUDA_HOME/bin
    export CUDACXX=$CUDA_HOME/bin/nvcc
    export CUDA_LIB=${CUDA_HOME}/lib

    ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

    ./configure \
        --prefix=${prefix} \
        --with-cudac=${CUDACXX} \
        --with-cuda-dir=${CUDA_HOME} \
        --with-nccl-dir=${prefix} \
        --with-mpiexec-executable=${bindir}/mpiexec \
        --with-mpi-dir=${prefix} \
        --with-zlib-dir=${prefix} \
        --with-hdf5-vfd-gds=0 \
        --with-hdf5-dir=${prefix} \
        --num-threads=${nproc} \
        --with-cxx=${CXX} \
        --with-cc=${CC} \
        --CXXFLAGS="${CPPFLAGS}" \
        --CFLAGS="${CFLAGS}" \
        --with-clean \
        --cmake-executable=${host_bindir}/cmake \
        -- "-DCMAKE_TOOLCHAIN_FILE=/opt/toolchains/${bb_full_target}/target_${target}_clang.cmake" \
            "-DCMAKE_CUDA_HOST_COMPILER=$(which clang++)" \


    # Patch redop header that is installed by configure script
    cd ${WORKSPACE}/srcdir
    atomic_patch -p1 ./legion_redop.patch

    # Go back to main dir
    cd ${WORKSPACE}/srcdir/legate

    make install -j ${nproc} PREFIX=${prefix}
    install_license ${WORKSPACE}/srcdir/legate/LICENSE

    if [[ "${target}" == aarch64-linux-* ]]; then
    # ensure products directory is clean
    rm -rf ${prefix}/cuda
    fi
    """

    return script

end

function get_script(cuda::Val{false})
    script = raw"""

    # We will build with clang
    export CC="clang"
    export CXX="clang++"
    export BUILD_CXX=$(which clang++)
    export BUILD_CC=$(which clang)

    # Put new CMake first on path
    export PATH=${host_bindir}:$PATH

    # Install Python 3.11 (via miniconda)
    cd ${WORKSPACE}/srcdir
    bash miniconda.sh -b -p ${host_bindir}/miniconda

    # Create venv and install configure script dependencies
    ${host_bindir}/miniconda/bin/python -m venv ./venv
    source ./venv/bin/activate
    pip install --upgrade pip
    pip install rich typing_extensions packaging

    python -c "import rich, typing_extensions, packaging; print('Python deps installed and working!')"

    cd ${WORKSPACE}/srcdir/legate

    ### Set Up CUDA ENV Vars

    export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
    export CFLAGS="${CFLAGS} -I${prefix}/include"
    export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"

    ./configure \
        --prefix=${prefix} \
        --with-cuda=0 \
        --with-mpiexec-executable=${bindir}/mpiexec \
        --with-mpi-dir=${prefix} \
        --with-zlib-dir=${prefix} \
        --with-hdf5-vfd-gds=0 \
        --with-hdf5-dir=${prefix} \
        --num-threads=${nproc} \
        --with-cxx=${CXX} \
        --with-cc=${CC} \
        --CXXFLAGS="${CPPFLAGS}" \
        --CFLAGS="${CFLAGS}" \
        --with-clean \
        --cmake-executable=${host_bindir}/cmake \
        -- "-DCMAKE_TOOLCHAIN_FILE=/opt/toolchains/${bb_full_target}/target_${target}_clang.cmake" \
            "-DCMAKE_CUDA_HOST_COMPILER=$(which clang++)" \


    # Patch redop header that is installed by configure script
    cd ${WORKSPACE}/srcdir
    atomic_patch -p1 ./legion_redop.patch

    # Go back to main dir
    cd ${WORKSPACE}/srcdir/legate

    make install -j ${nproc} PREFIX=${prefix}
    install_license ${WORKSPACE}/srcdir/legate/LICENSE

    """

    return script

end