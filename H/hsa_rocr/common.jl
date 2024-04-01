const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCR-Runtime.git"
const ROCM_TAGS = Dict(
    v"4.2.0" => "337e3e55d09cda3fbc8e7f99eece8aeadbec226c",
    v"4.5.2" => "f95a10171798ff61efdb672396bb1fa6cb6259f5",
    v"5.2.3" => "dbc2f403d7a212fab737a3f7e1775bd9608d5496",
    v"5.4.4" => "2e52dc810a3a3066d0c72809defae52fdf0f23cb",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]
const PATCHES = Dict(
    v"4.2.0" => raw"""
    atomic_patch -p1 ../patches/1-no-werror.patch
    """,
    v"4.5.2" => raw"""
    atomic_patch -p1 ../patches/1-no-werror.patch
    atomic_patch -p1 ../patches/musl-affinity.patch
    """,
    v"5.2.3" => raw"""
    atomic_patch -p1 ../patches/musl-affinity.patch
    atomic_patch -p1 ../patches/musl-pthread-rwlock.patch
    """,
    v"5.4.4" => raw"""
    atomic_patch -p1 ../patches/musl-affinity.patch
    atomic_patch -p1 ../patches/musl-clock-gettime.patch
    atomic_patch -p1 ../patches/musl-pthread-rwlock.patch
    """,
)

const PRODUCTS = [LibraryProduct(["libhsa-runtime64"], :libhsa_runtime64)]
const NAME = "hsa_rocr"

function configure_build(version)
    buildscript = raw"""
    # check if we need to use a more recent glibc
    if [[ -f "$prefix/usr/include/sched.h" ]]; then
        GLIBC_ARTIFACT_DIR=$(dirname $(dirname $(dirname $(realpath $prefix/usr/include/sched.h))))
        rsync --archive ${GLIBC_ARTIFACT_DIR}/ /opt/${target}/${target}/sys-root/
    fi

    cd ${WORKSPACE}/srcdir/ROCR-Runtime*/
    """ *
    PATCHES[version] *
    raw"""
    mkdir build && cd build

    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBITCODE_DIR=${prefix}/amdgcn/bitcode \
        ../src

    make -j${nproc}
    make install
    install_license ${WORKSPACE}/srcdir/ROCR-Runtime*/LICENSE.txt
    """
    sources = [
        GitSource(ROCM_GIT, ROCM_TAGS[version]),
        DirectorySource("./bundled"),
        DirectorySource("../scripts"),
    ]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        Dependency("hsakmt_roct_jll", version),
        Dependency("ROCmDeviceLibs_jll", version),
        Dependency("NUMA_jll"),
        Dependency("XML2_jll"),
        Dependency("Elfutils_jll"),
    ]
    if version < v"5"
        # 1.2.12 causes undefined variable errors:
        # https://github.com/JuliaPackaging/Yggdrasil/pull/5367
        push!(dependencies, Dependency("Zlib_jll", v"1.2.11"))
    else
        push!(dependencies, Dependency("Zlib_jll"))
    end
    #if version >= v"5.4.4"
        # Need this for CLOCK_BOOTTIME
        push!(dependencies,
              BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.17");
                              platforms = filter(p->libc(p)=="glibc", ROCM_PLATFORMS)))
    #end
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
