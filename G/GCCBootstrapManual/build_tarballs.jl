using BinaryBuilder2
using BinaryBuilder2: BuildTargetSpec, gcc_platform

# A bootstrap GCC for macOS and FreeBSD targets.  crosstool-ng (which builds `GCCBootstrap`)
# supports neither, so this builds GCC directly against the target's SDK/sysroot.  It is the
# compiler behind `CToolchain(; vendor=:gcc_bootstrap)` for these targets.
name = "GCCBootstrapManual"
version = v"14.2.0"

sources = [
    ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-$(version)/gcc-$(version).tar.xz",
                  "a7b39bc69cbf9e25826c5a60ab26477001f7c08d85cec04bc0e29cabed6f3cc9"),
    ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.1.0.tar.xz",
                  "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f";
                  target="gcc-$(version)"),
    ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.2.1.tar.gz",
                  "17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459";
                  target="gcc-$(version)"),
    ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2",
                  "fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0";
                  target="gcc-$(version)"),
    ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz",
                  "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2";
                  target="gcc-$(version)"),
    DirectorySource("./bundled/patches"; target="patches"),
]

script = raw"""
cd ${WORKSPACE}/srcdir

# Force everything to default to cross compiling; this avoids differences
# in behavior between when we target our own triplet
for f in $(find . -name configure); do
    sed -i.bak -e 's&cross_compiling=no&cross_compiling=yes&g' "${f}"
    sed -i.bak -e 's&is_cross_compiler=no&is_cross_compiler=yes&g' "${f}"
done

GCC_CONF_ARGS=()
if [[ "${target}" == x86_64* ]]; then
    GCC_CONF_ARGS+=( --with-arch=x86-64 )
fi

# We need a `c++filt` for libstdc++ generation.  Make sure it's named appropriately:
mkdir -p /usr/local/bin
ln -s "$(which "${HOST_CXXFILT}")" /usr/local/bin/c++filt

if [[ "${target}" == *-darwin* ]]; then
    GCC_CONF_ARGS+=( --enable-plugin )

    # GCC doesn't know how to use availability macros properly, so tell it not to use functions
    # that are available only starting in later macOS versions such as `clock_gettime` or `mkostemp`
    export ac_cv_func_clock_gettime=no
    export ac_cv_func_mkostemp=no
elif [[ "${target}" == *-freebsd ]]; then
    # GCC needs the FreeBSD version in the target triplet
    target_suffix="${FREEBSD_TARGET_SDK}"
fi

# Get rid of version numbers at the end of GCC deps
cd $WORKSPACE/srcdir/gcc-*/
for proj in mpfr mpc isl gmp; do
    if [[ -d $(echo ${proj}-*) ]]; then
        echo "Moving $(echo ${proj}-*) -> ${proj}"
        mv ${proj}-* ${proj}
    fi
done

for p in ${WORKSPACE}/srcdir/patches/gcc-*.patch; do
    atomic_patch -p1 "${p}"
done

# Build in separate directory
mkdir -p $WORKSPACE/srcdir/gcc_build
cd $WORKSPACE/srcdir/gcc_build

# Force `make` to use `/bin/true` instead of `makeinfo` so that we don't
# die while failing to build docs.
MAKEVARS=( MAKEINFO=true )

for TOOL in CC CPP CXX AS AR NM LD RANLIB; do
    unset "${TOOL}"
    BUILD_NAME="BUILD_${TOOL}"
    export ${TOOL}_FOR_BUILD=${!BUILD_NAME}
    TARGET_NAME="TARGET_${TOOL}"
    if [[ -v "${TARGET_NAME}" ]]; then
        export ${TOOL}_FOR_TARGET=${!TARGET_NAME}

        # These target tool autodetections do not work
        export ac_cv_path_${TOOL}_FOR_TARGET=${!TARGET_NAME}
    fi
done

# libcc1 fails with an error about `-rdynamic` unless we define this
if [[ -v "NM_FOR_TARGET" ]]; then
    export gcc_cv_nm="${NM_FOR_TARGET}"
fi

# Make sure the tools that GCC itself wants to use ("ld", "as", "dsymutil") are available
# not just as "host-ld" or "host-as", etc... Otherwise, the `collect2` we generate looks
# for these names.  This results in e.g. `--with-ld=/opt/.../x86_64-apple-darwin20-ld`
for TOOL in LD AS DSYMUTIL; do
    if [[ -v "TARGET_${TOOL}" ]]; then
        tool="$(tr '[:upper:]' '[:lower:]' <<<"${TOOL}")"
        GCC_CONF_ARGS+=( --with-${tool}="$(which "${target}-${tool}")" )
    fi
done
# `collect2` is useless without `--with-ld` and `--with-as`, so fail early without them
[[ "${GCC_CONF_ARGS[@]}" == *--with-ld=* ]]
[[ "${GCC_CONF_ARGS[@]}" == *--with-as=* ]]

$WORKSPACE/srcdir/gcc-*/configure \
    --prefix="${host_prefix}" \
    --build="${build}" \
    --host="${host}" \
    --target="${target}${target_suffix:-}" \
    --disable-multilib \
    --disable-bootstrap \
    --disable-werror \
    --enable-threads=posix \
    --enable-languages=c,c++ \
    --with-build-sysroot="${target_prefix}/${target}" \
    --with-sysroot="${host_prefix}/${target}" \
    --program-prefix="${target}-" \
    ${GCC_CONF_ARGS[@]}

make -j${nproc} "${MAKEVARS[@]}"
make install "${MAKEVARS[@]}"

# Remove misleading libtool archives
rm -f ${prefix}/${target}/lib*/*.la

# Remove heavy doc directories
rm -rf ${prefix}/share/man

install_license ${WORKSPACE}/srcdir/gcc-*/COPYING*

for proj in mpfr mpc isl gmp; do
    for f in ${WORKSPACE}/srcdir/gcc-*/${proj}/COPYING* ${WORKSPACE}/srcdir/gcc-*/${proj}/COPYRIGHT*; do
        [[ -f "${f}" ]] || continue
        install -Dvm 644 "${f}" "${prefix}/share/licenses/GCCBootstrapManual/${proj}-$(basename "${f}")"
    done
done
"""

host_platforms = [
    Platform("x86_64", "linux"),
    # aarch64 hosts wait for aarch64 builders on Yggdrasil CI, so that they can be built natively.
    #Platform("aarch64", "linux"),
]
target_platforms = filter(p -> Sys.isapple(p) || Sys.isfreebsd(p), supported_platforms())
platforms = [CrossPlatform(host => target) for host in host_platforms, target in target_platforms][:]

products = [
    FileProduct("bin", :bindir),
    ExecutableProduct("\${target}-gcc", :gcc),
    ExecutableProduct("\${target}-g++", :gxx),
]

# GCC is built for `host` against the target's SDK/sysroot, which is installed into
# `${target_prefix}/${target}` as GCC's build sysroot.
function gcc_build_spec_generator(host, platform)
    target_str = triplet(gcc_platform(platform.target))
    if Sys.isapple(platform.target)
        sysroot = JLLSource("macOSSDK_jll", platform.target; version=v"11.1.1", target=target_str)
    elseif Sys.isfreebsd(platform.target)
        sysroot = JLLSource("FreeBSDSysroot_jll", platform.target; version=v"14.1.0", target=target_str)
    else
        throw(ArgumentError("Don't know how to install libc sources for $(triplet(platform.target))"))
    end

    return [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture=false), HostToolsToolchain()],
            [],
            [],
            Set([:native]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture=false)],
            [],
            [],
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            CrossPlatform(host => platform.target),
            [BinutilsToolchain(:gcc_bootstrap)],
            [sysroot],
            [],
            Set{Symbol}(),
        ),
    ]
end

# libstdc++ for macOS targets links the SDK's `/usr/lib/libiconv.2.dylib`
gcc_audit_config(platform) = Sys.isapple(platform.target) ?
    AuditConfig(; extra_system_libraries = ["libiconv.2.dylib"]) : AuditConfig()

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    build_spec_generator = gcc_build_spec_generator,
    duplicate_extraction_handling = :ignore_all,
    audit_config = gcc_audit_config,
)
