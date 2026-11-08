# Apple's cctools (`ld64`, `lipo`, `install_name_tool`, ...) via tpoechtrager's port, which
# BinaryBuilder2's toolchains use as the binutils for macOS targets.
using BinaryBuilder2
using BinaryBuilder2: BuildTargetSpec

name = "CCTools"
version = v"986"

sources = [
    GitSource("https://github.com/tpoechtrager/cctools-port",
              "2a3e1c2a6ff54a30f898b70cfb9ba1692a55fad7"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/cctools-port/cctools

for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p2 ${patch}
done

install_license ./APPLE_LICENSE
install_license ./COPYING

# The uname wrapper confuses the build
rm -f $(which uname)

./configure --prefix=${prefix} \
            --build=${build} \
            --host=${host} \
            --target=${target} \
            --with-libtapi=${host_prefix} \
            --disable-lto-support
make -j${nproc}
make -j${nproc} install
"""

host_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
]
mac_platforms = filter(Sys.isapple, supported_platforms())
platforms = [CrossPlatform(host => target) for host in host_platforms, target in mac_platforms][:]

products = [
    ExecutableProduct(raw"${target}-ld", :ld),
    ExecutableProduct(raw"${target}-lipo", :lipo),
    ExecutableProduct(raw"${target}-install_name_tool", :install_name_tool),
]

function cctools_build_spec_generator(host, platform)
    return [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain(), HostToolsToolchain()],
            [],
            [],
            Set([:native]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain()],
            [
                JLLSource("libtapi_jll"),
                JLLSource("Zlib_jll"; version=v"1.4.1"),
            ],
            [],
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            [],
            [],
            [],
            Set{Symbol}(),
        ),
    ]
end

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    build_spec_generator = cctools_build_spec_generator,
)
