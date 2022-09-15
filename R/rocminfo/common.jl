const NAME = "rocminfo"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/rocminfo/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "6952b6e28128ab9f93641f5ccb66201339bb4177bb575b135b27b69e2e241996",
    v"4.5.2" => "5ea839cd1f317cbc72ea1e3634a75f33a458ba0cb5bf48377f08bb329c29222d",
    v"5.2.3" => "38fe8db21077100ee2242bd087371f6b8e0078d3a269e145d3a4ab314d0b8902",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
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
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", ROCM_TAGS[version]),
    ]
    dependencies = [
        Dependency("hsakmt_roct_jll", version),
        Dependency("hsa_rocr_jll", version),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
