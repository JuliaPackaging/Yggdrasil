using BinaryBuilder2

name = "GCCBootstrap"
version = v"14.2.0"

# GCC and binutils cross compilers, plus a libc sysroot for each target, built with
# crosstool-ng.  This is BinaryBuilder2's `CToolchain(; vendor=:gcc_bootstrap)`, the
# toolchain that builds everything else.

# Mirrors for a file under https://ftp.gnu.org/gnu/, tried in order.
gnu_mirrors(path) = [
    "https://ftpmirror.gnu.org/$(path)",
    "https://mirrors.kernel.org/gnu/$(path)",
    "https://ftp.fau.de/gnu/$(path)",
    "https://ftp.gnu.org/gnu/$(path)",
]

sources = [
    # crosstool-ng can download these itself, but we'd rather download them ourselves
    FileSource(gnu_mirrors("gcc/gcc-$(version)/gcc-$(version).tar.xz"),
               "a7b39bc69cbf9e25826c5a60ab26477001f7c08d85cec04bc0e29cabed6f3cc9"),
    FileSource(gnu_mirrors("mpfr/mpfr-4.2.1.tar.xz"),
               "277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2"),
    FileSource(gnu_mirrors("mpc/mpc-1.3.1.tar.gz"),
               "ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8"),
    FileSource("https://libisl.sourceforge.io/isl-0.26.tar.xz",
               "a0b5cb06d24f9fa9e77b55fabbe9a3c94a336190345c2555f9915bb38e976504"),
    FileSource(gnu_mirrors("gmp/gmp-6.3.0.tar.xz"),
               "a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898"),
    FileSource(["https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.4.289.tar.xz",
                "https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.4.289.tar.xz"],
               "1e3e5fc052c8e15f8eaa37d30bf4f0b3eef7430dd234d9fed0d0005852a06d10"),
    FileSource(gnu_mirrors("glibc/glibc-2.17.tar.xz"),
               "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e"),
    FileSource(gnu_mirrors("glibc/glibc-2.19.tar.xz"),
               "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2"),
    FileSource(gnu_mirrors("glibc/glibc-2.35.tar.xz"),
               "5123732f6b67ccd319305efd399971d58592122bcc2a6518a1bd2510dd0cf52e"),
    FileSource(["https://musl.libc.org/releases/musl-1.2.5.tar.gz",
                "https://sources.buildroot.net/musl/musl-1.2.5.tar.gz",
                "https://sources.openwrt.org/musl-1.2.5.tar.gz",
                "https://distfiles.macports.org/musl/musl-1.2.5.tar.gz"],
               "a9a118bbe84d8764da0ea0d28b3ab3fae8477fc7e4085d90102b8596fc7c75e4"),
    FileSource(["https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v12.0.0.tar.bz2",
                "https://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v12.0.0.tar.bz2"],
               "cc41898aac4b6e8dd5cffd7331b9d9515b912df4420a3a612b5ea2955bbeed2f"),
    FileSource(["https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz",
                "https://zlib.net/fossils/zlib-1.3.1.tar.gz"],
               "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"),
    FileSource(["https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz",
                "https://sources.buildroot.net/zstd/zstd-1.5.6.tar.gz"],
               "8c29e06cf42aacc1eafc4077ae2ec6c6fcb96a626157e0593d5e82a34fd403c1"),
    FileSource(gnu_mirrors("ncurses/ncurses-6.4.tar.gz"),
               "6931283d9ac87c5073f30b6290c4c75f21632bb4fc3603ac8100812bed248159"),
    FileSource(gnu_mirrors("libiconv/libiconv-1.16.tar.gz"),
               "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"),
    FileSource(gnu_mirrors("gettext/gettext-0.23.1.tar.xz"),
               "c1f97a72a7385b7e71dd07b5fea6cdaf12c9b88b564976b23bd8c11857af2970"),
    FileSource(gnu_mirrors("binutils/binutils-2.29.1.tar.xz"),
               "e7010a46969f9d3e53b650a518663f98a5dde3c3ae21b7d71e5e6803bc36b577"),
    FileSource(gnu_mirrors("binutils/binutils-2.43.1.tar.xz"),
               "13f74202a3c4c51118b797a39ea4200d3f6cfbe224da6d1d95bb938480132dfd"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/

# Build the toolchain with the rootfs's own compiler rather than one of our toolchains,
# so that it doesn't depend on a toolchain we've already built.
apt update && apt install -y --no-install-recommends build-essential

# crosstool-ng looks up `python` on the `PATH`, but our host tools only provide `python3`.
ln -sf "$(which python3)" /usr/bin/python

# Generate a stripped-down crosstool-ng config for this target, then let
# `ct-ng upgradeconfig` fill in all the other options.
${WORKSPACE}/srcdir/gen_config.sh > .config
ct-ng upgradeconfig

export CT_ALLOW_BUILD_AS_ROOT_SURE=1
ct-ng build

# crosstool-ng's tuple differs from `${target}` (e.g. `arm-linux-gnueabihf` for both
# armv6l and armv7l); the products below are named after it.
GCC_TARGET=$(basename $(compgen -G ${host_bindir}/*-gcc))
GCC_TARGET=${GCC_TARGET%*-gcc}

# Some netfilter headers differ only in case, which breaks case-insensitive
# filesystems; the `LinuxKernelHeaders` recipe renames them the same way.
if [[ "${target}" == *linux* ]]; then
    NF="${host_prefix}/${GCC_TARGET}/sysroot/usr/include/linux/netfilter"
    for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
        mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
    done
    for NAME in ECN TTL; do
        mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
    done
    mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"
fi

# Put the licenses of all the bundled projects under `GCCBootstrap`
mkdir -p ${prefix}/share/GCCBootstrap_licenses
mv ${prefix}/share/licenses/* ${prefix}/share/GCCBootstrap_licenses/
mv ${prefix}/share/GCCBootstrap_licenses ${prefix}/share/licenses/GCCBootstrap
"""

# crosstool-ng builds glibc, musl and mingw-w64 toolchains (`gen_config.sh` configures
# each one); it can't build the macOS (cctools and an SDK) or FreeBSD toolchains, which
# come from other recipes.
targets = filter(p -> !Sys.isapple(p) && !Sys.isbsd(p), supported_platforms())

# `CrosstoolNG_jll` only exists for x86_64-linux-gnu, so that is the only host.
host = Platform("x86_64", "linux")
platforms = [CrossPlatform(host => target) for target in targets]

products = [
    ExecutableProduct("\${bindir}/\${GCC_TARGET}-$(tool)", varname)
    for (tool, varname) in (
        # binutils
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
        # GCC
        ("cc", :cc),
        ("gcc", :gcc),
        ("cpp", :cpp),
        ("g++", :gxx),
    )
]

host_dependencies = [
    JLLSource("CrosstoolNG_jll", host; version=v"1.27.0"),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    host,
    host_dependencies,
    host_toolchains = [HostToolsToolchain()],
    target_toolchains = [],
)
