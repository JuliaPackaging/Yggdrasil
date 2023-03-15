# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GCCBootstrap"
version = v"9.4.0"

# Collection of sources required to complete build
sources = [
    # crosstool-ng will provide the build script
    ArchiveSource("http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.25.0_rc1.tar.bz2",
                  "8a839df71bea7b2c411447b41b917f2142482df171733ddb92d615cec2f0f43a"),

    # We provide some configs for crostool-ng
    DirectorySource("./bundled"),

    # crosstool-ng can download the files, but we'd rather download them ourselves
    FileSource("http://mirrors.kernel.org/gnu/gcc/gcc-9.4.0/gcc-9.4.0.tar.xz",
               "c95da32f440378d7751dd95533186f7fc05ceb4fb65eb5b85234e6299eb9838e"),
    FileSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.1.0.tar.xz",
               "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f"),
    FileSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.2.1.tar.gz",
               "17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459"),
    FileSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2",
               "fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0"),
    FileSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz",
               "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2"),
    FileSource("http://mirrors.kernel.org/pub/linux/kernel/v4.x/linux-4.1.49.tar.xz",
               "ff2e0ea5c536650aef64447c3aaa49c1a25e8f1db4ec4f7da700d3176f512ba8"),
    FileSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.19.tar.xz",
               "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2"),
    FileSource("https://musl.libc.org/releases/musl-1.2.2.tar.gz",
               "9b969322012d796dc23dda27a35866034fa67d8fb67e0e2c45c913c3d43219dd"),
    FileSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v9.0.0.tar.bz2",
               "1929b94b402f5ff4d7d37a9fe88daa9cc55515a6134805c104d1794ae22a4181"),
    FileSource("https://github.com/madler/zlib/archive/refs/tags/v1.2.11.tar.gz",
               "629380c90a77b964d896ed37163f5c3a34f6e6d897311f1df2a7016355c45eff",
               filename="zlib-1.2.11.tar.gz"),
    FileSource("http://mirrors.kernel.org/gnu/ncurses/ncurses-6.2.tar.gz",
               "30306e0c76e0f9f1f0de987cf1c82a5c21e1ce6568b9227f7da5b71cbea86c9d"),
    FileSource("http://mirrors.kernel.org/gnu/libiconv/libiconv-1.16.tar.gz",
               "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"),
    FileSource("http://mirrors.kernel.org/gnu/gettext/gettext-0.21.tar.xz",
               "d20fcbb537e02dcf1383197ba05bd0734ef7bf5db06bdb241eb69b7d16b73192"),
    FileSource("http://mirrors.kernel.org/gnu/binutils/binutils-2.29.1.tar.xz",
               "e7010a46969f9d3e53b650a518663f98a5dde3c3ae21b7d71e5e6803bc36b577"),
    FileSource("http://mirrors.kernel.org/gnu/binutils/binutils-2.38.tar.xz",
               "e316477a914f567eccc34d5d29785b8b0f5a10208d36bbacedcc39048ecfe024"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/crosstool-ng*/

# These tools will help us to bootstrap
apk add build-base texinfo help2man ncurses-dev

# Copy in our extra patches for all packages
for package in ${WORKSPACE}/srcdir/patches/*; do
    package="$(basename "${package}")"
    for version in ${WORKSPACE}/srcdir/patches/${package}/*; do
        version="$(basename "${version}")"
        if [ ! -d packages/${package}/${version} ]; then
            continue
        fi
        cp -v ${WORKSPACE}/srcdir/patches/${package}/${version}/* packages/${package}/${version}/
    done
done

# Disable some checks that ct-ng performs
export CT_ALLOW_BUILD_AS_ROOT_SURE=1

# Unset some things that BB automatically inserts into the environment,
# but which crosstool-ng rightfully complains about.
unset LD_LIBRARY_PATH
for TOOL in CC CXX LD AS AR FC OBJCOPY OBJDUMP RANLIB STRIP LIPO MESON NM READELF; do
    unset "${TOOL}" "BUILD_${TOOL}" "${TOOL}_BUILD" "${TOOL}_FOR_BUILD" "HOST${TOOL}"
done
PATH="$(printf "%s" "$(echo -n "${PATH}" | tr ':' '\n' | grep -v "/opt")" | tr '\n' ':')"


# Build crosstool-ng for the current host
./configure --enable-local
make -j${nproc}

# Generate the appropriate crosstool-ng config file for our current target
${WORKSPACE}/srcdir/gen_config.sh > .config
cat .config

# This takes our stripped-down config and fills out all the other options
./ct-ng upgradeconfig

# Do the actual build!
./ct-ng build

# Fix case-insensitivity problems in netfilter headers
if [[ "${target}" == *linux* ]]; then
    NF="${prefix}/${target}/sysroot/usr/include/linux/netfilter"
    for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
        mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
    done
    for NAME in ECN TTL; do
        mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
    done
    mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"
fi

# Move licenses to the right spot
mkdir -p /tmp/GCCBootstrap
mv ${prefix}/share/licenses/* /tmp/GCCBootstrap
mv /tmp/GCCBootstrap ${prefix}/share/licenses/

[[ -f "${bindir}/${target}-gcc" ]]
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> Sys.islinux(p) || Sys.iswindows(p), supported_platforms())

# The products that we will ensure are always built
products = Product[
    #ExecutableProduct("gcc", :gcc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
