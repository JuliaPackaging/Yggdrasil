const NAME = "rocminfo"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/rocminfo.git"
const ROCM_TAGS = Dict(
    v"4.2.0" => "10da0a71da6700c91e8cd204927cca0d9461b586",
    v"4.5.2" => "1452f8fa24b2a33051c326dc7b21bff0450b4c66",
    v"5.2.3" => "cf92f649ab0db4084fc8b2b6e891670f60edc314",
    v"5.4.4" => "d8f236cd8180ee0f1fc1da497d0f576a446b86ab",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
# check if we need to use a more recent glibc
if [[ -f "$prefix/usr/include/sched.h" ]]; then
    GLIBC_ARTIFACT_DIR=$(dirname $(dirname $(dirname $(realpath $prefix/usr/include/sched.h))))
    rsync --archive ${GLIBC_ARTIFACT_DIR}/ /opt/${target}/${target}/sys-root/
fi

cd ${WORKSPACE}/srcdir/rocminfo*/

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DROCM_DIR=${prefix} \
    ..

make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/rocminfo*/License.txt
"""

const PRODUCTS = [
    ExecutableProduct("rocminfo", :rocminfo),
    ExecutableProduct("rocm_agent_enumerator", :rocm_agent_enumerator),
]

function configure_build(version)
    sources = [
        GitSource(ROCM_GIT, ROCM_TAGS[version]),
    ]
    dependencies = Any[
        Dependency("hsakmt_roct_jll", version),
        Dependency("hsa_rocr_jll", version),
    ]
    glibc_platforms = filter(ROCM_PLATFORMS) do p
        libc(p) == "glibc"
    end
    if version >= v"5.4.4"
        # We seem to need this for linking against libhsa-runtime64
        push!(dependencies,
              BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.17");
                                          platforms=glibc_platforms))
    end
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
