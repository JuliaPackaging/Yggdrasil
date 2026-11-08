using BinaryBuilder2, Pkg

script = raw"""
cd ${WORKSPACE}/srcdir/binutils-*/

update_configure_scripts
for p in ${WORKSPACE}/srcdir/patches/binutils-*.patch; do
    atomic_patch -p1 "${p}"
done

# Map `BUILD_CC` to `CC_FOR_BUILD`, etc...
BUILD_ENVS=( $(env | grep "^BUILD_" | cut -d'=' -f1) )
for BUILD_ENV in "${BUILD_ENVS[@]}"; do
    ENV="${BUILD_ENV#BUILD_}"
    export "${ENV}_FOR_BUILD=${!BUILD_ENV}"
done

./configure --prefix=${host_prefix} \
    --build=${build} \
    --host=${host} \
    --target=${target} \
    --with-sysroot=${host_prefix}/${target} \
    --disable-multilib \
    --program-prefix="${target}-" \
    --disable-werror \
    --enable-new-dtags \
    --enable-deterministic-archives \
    --disable-gprofng

# Skip building the docs
MAKEVARS=( MAKEINFO=true )

# bison can't regenerate `plural.c` from `plural.y` when cross-compiling:
# https://sourceware.org/bugzilla/show_bug.cgi?id=22941
touch intl/plural.c

make -j${nproc} ${MAKEVARS[@]}
make install ${MAKEVARS[@]}
"""

host_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
]

# macOS targets use cctools instead of binutils
target_platforms = filter(!Sys.isapple, supported_platforms(CToolchain))

platforms = [
    vec([CrossPlatform(host, target) for host in host_platforms, target in target_platforms]);
    [CrossPlatform(target, target) for target in target_platforms if target ∉ host_platforms]
]

products = [
    ExecutableProduct("\${bindir}/\${target}-$(tool)", varname)
    for (tool, varname) in (
        ("ar", :ar),
        ("as", :as),
        ("ld", :ld),
        ("nm", :nm),
        ("objcopy", :objcopy),
        ("objdump", :objdump),
        ("ranlib", :ranlib),
        ("readelf", :readelf),
        ("strings", :strings),
        ("strip", :binutils_strip),
    )
]

build_tarballs(;
    src_name = "Binutils",
    src_version = v"2.41",
    sources = [
        ArchiveSource("https://ftpmirror.gnu.org/gnu/binutils/binutils-2.41.tar.xz",
                      "ae9a5789e23459e59606e6714723f2d3ffc31c03174191ef0d015bdf06007450"),
        DirectorySource("./bundled/patches"; target="patches"),
    ],
    target_dependencies = [
        JLLSource(
            "Zlib_jll";
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                source="https://github.com/staticfloat/Zlib_jll.jl",
            ),
        ),
    ],
    script,
    platforms,
    products,
    host_toolchains = [CToolchain(;vendor=:gcc_bootstrap), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:gcc_bootstrap)],
)
