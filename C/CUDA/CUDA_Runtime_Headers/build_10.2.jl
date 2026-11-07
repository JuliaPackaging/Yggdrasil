# CUDA 10.2 has no redistributable archives, so like CUDA_Compiler_jll we repackage the
# headers of the CUDA_SDK_jll build, which does not separate the runtime headers from those
# of the rest of the toolkit.

get_script() = raw"""
# First, find (true) CUDA toolkit directory in ~/.artifacts somewhere
CUDA_ARTIFACT_DIR=$(dirname $(dirname $(realpath $prefix/cuda/bin/ptxas${exeext})))
cd ${CUDA_ARTIFACT_DIR}

# Clear out our prefix
rm -rf ${prefix}/*

# license
install_license EULA.txt

mkdir -p ${includedir}
cp -r include/* ${includedir}
"""

# CUDA 10.2 has no `cuda_bf16.h`
get_products() = [
    FileProduct("include/cuda_runtime.h", :cuda_runtime_h),
    FileProduct("include/cuda_fp16.h", :cuda_fp16_h),
]
