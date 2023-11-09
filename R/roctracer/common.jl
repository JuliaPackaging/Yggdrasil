const ROCM_GIT = "https://github.com/ROCm-Developer-Tools/roctracer.git"
const ROCM_TAGS = Dict(
    # v"4.2.0" => "337e3e55d09cda3fbc8e7f99eece8aeadbec226c",
    # v"4.5.2" => "f95a10171798ff61efdb672396bb1fa6cb6259f5",
    # v"5.2.3" => "dbc2f403d7a212fab737a3f7e1775bd9608d5496",
    v"5.4.4" => "0e280ca073259a550de20b38ec77c7c68938f037",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const PRODUCTS = [LibraryProduct(["libhsa-runtime64"], :libhsa_runtime64)]
const NAME = "roctracer"

function configure_build(version)
    buildscript = raw"""
    # check if we need to use a more recent glibc
    if [[ -f "$prefix/usr/include/sched.h" ]]; then
        GLIBC_ARTIFACT_DIR=$(dirname $(dirname $(dirname $(realpath $prefix/usr/include/sched.h))))
        rsync --archive ${GLIBC_ARTIFACT_DIR}/ /opt/${target}/${target}/sys-root/
    fi

    cd ${WORKSPACE}/srcdir/roctracer*/
    mkdir build && cd build

    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        ..

    make -j${nproc}
    make install
    install_license ${WORKSPACE}/srcdir/roctracer*/LICENSE
    """
    sources = [
        GitSource(ROCM_GIT, ROCM_TAGS[version]),
    ]
    dependencies = Any[
        Dependency("hsa_rocr_jll", compat=string(version)),
        Dependency("HIP_jll", compat=string(version)),
    ]
    #if version >= v"5.4.4"
        # Need this for CLOCK_BOOTTIME
        push!(dependencies,
              BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.17");
                              platforms = filter(p->libc(p)=="glibc", ROCM_PLATFORMS)))
    #end
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
