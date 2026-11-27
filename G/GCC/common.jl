using BinaryBuilder2
using BinaryBuilder2: BuildTargetSpec, gcc_platform, get_target_spec_by_name, get_default_target_spec,
                      default_build_spec_generator

# GCC cross and native compilers, the compilers behind `CToolchain(; vendor=:gcc)`.
# Each build is split into four JLLs:
# - `GCC_jll`: the compiler itself, for the `CrossPlatform(host => target)`
# - `libstdcxx_jll`: the target's C++ headers and `libstdc++`
# - `GCC_support_libraries_jll`: the target's other runtime libraries (`libgcc_s`,
#   `libgomp`, `libatomic`, `libssp`, `libquadmath`, ...)
# - `GCC_crt_objects_jll`: the target's `libgcc.a` and `crt*.o` startup objects
# The three target JLLs are identical for every host, so their artifacts are keyed by the
# target platform alone.  One more build provides only `libstdcxx_jll`, a MemorySanitizer
# `libstdc++` for `x86_64-linux-gnu-sanitize+memory` (GCC 14 only).
# Each `GCC@<version>/build_tarballs.jl` builds one GCC version from these pieces.

const gcc_script_base = raw"""
# GCC cannot build with MemorySanitizer; this target builds only libstdc++, with clang
if [[ "${bb_full_target}" == *-sanitize+memory* ]]; then
    source ${WORKSPACE}/srcdir/bundled/libstdcxx_sanitized.sh
    exit 0
fi

cd ${WORKSPACE}/srcdir

# `gcc_version` and `lib64` are also used by the extraction scripts and product paths
gcc_version="$(echo gcc-* | cut -d- -f2)"
# Without multilib, GCC installs riscv64 target libraries into `lib`
if [[ "${target}" != *mingw* ]] && [[ "${target}" != *darwin* ]] && [[ "${target}" != *freebsd* ]] && [[ "${target}" != riscv64-* ]]; then
    lib64="lib${target_nbits%32}"
else
    lib64="lib"
fi

# Force everything to default to cross compiling; this avoids differences
# in behavior between when we target our own triplet
for f in $(find . -name configure); do
    sed -i.bak -e 's&cross_compiling=no&cross_compiling=yes&g' "${f}"
    sed -i.bak -e 's&is_cross_compiler=no&is_cross_compiler=yes&g' "${f}"
done

GCC_CONF_ARGS=()

## Architecture-dependent arguments
# Choose a default arch, and on arm*hf targets, pass `--with-float=hard` explicitly
if [[ "${target}" == arm*hf ]]; then
    # We choose the armv6 arch by default for compatibility
    GCC_CONF_ARGS+=( --with-float=hard --with-arch=armv6 --with-fpu=vfp )
elif [[ "${target}" == x86_64* ]]; then
    GCC_CONF_ARGS+=( --with-arch=x86-64 )
elif [[ "${target}" == i686* ]]; then
    GCC_CONF_ARGS+=( --with-arch=pentium4 )
elif [[ "${target}" == riscv64* ]]; then
    GCC_CONF_ARGS+=( --with-arch=rv64gc --with-abi=lp64d )
fi

# We need a `c++filt` for libstdc++ generation.  Make sure it's named appropriately:
mkdir -p /usr/local/bin
ln -s "$(which "${HOST_CXXFILT}")" /usr/local/bin/c++filt

## OS-dependent arguments
if [[ "${target}" == *-musl* ]]; then
    GCC_CONF_ARGS+=( --disable-libssp --disable-libmpx --disable-libmudflap )
    GCC_CONF_ARGS+=( --disable-libsanitizer --disable-symvers --enable-clocale=generic )
    export libat_cv_have_ifunc=no
    export ac_cv_have_decl__builtin_ffs=yes

elif [[ "${target}" == *-mingw* ]]; then
    # On mingw, we need to explicitly enable openmp
    GCC_CONF_ARGS+=( --enable-libgomp )

    # Target msvcrt, like our Mingw build
    GCC_CONF_ARGS+=( --with-default-msvcrt=msvcrt )

    # Match BB1's libstdc++ ABI, which does not use emutls (GCC <= 15 has no native TLS on Windows)
    GCC_CONF_ARGS+=( --disable-tls )

    # Mingw just always looks in `mingw/` instead of `usr/`, so we symlink it:
    mkdir -p ${host_prefix}/${target}
    ln -s . ${target_prefix}/${target}/mingw
    if [[ "${host}" == *-mingw* ]]; then
        ln -s . ${host_prefix}/${target}/mingw
    fi

elif [[ "${target}" == *-darwin* ]]; then
    GCC_CONF_ARGS+=( --enable-plugin )

    # GCC doesn't know how to use availability macros properly, so tell it not to use functions
    # that are available only starting in later macOS versions such as `clock_gettime` or `mkostemp`
    export ac_cv_func_clock_gettime=no
    export ac_cv_func_mkostemp=no

    # Without `-sdk_version`, ld64 leaves LC_BUILD_VERSION's SDK version of the runtime
    # dylibs (libstdc++, libgcc_s, ...) unset, which macOS 26's stricter dyld rejects.
    export LDFLAGS_FOR_TARGET="${LDFLAGS_FOR_TARGET:-} -Wl,-sdk_version,11.0"

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

for p in ${WORKSPACE}/srcdir/bundled/patches/gcc-*.patch; do
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
# for these names.  This results in e.g. `--with-ld=/opt/.../x86_64-linux-gnu-ld`
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

# A compiler that doesn't run on the build machine (a Canadian cross) can't build its own
# target libraries, and the bootstrap GCC may be too old to build them.  Those are the same
# for every host, so only the compiler and its host-side libraries are built there, and the
# target libraries come from the build of this target on the build machine.
config_sub="$(echo $WORKSPACE/srcdir/gcc-*/config.sub)"
if [[ "$(${config_sub} "${host}")" == "$(${config_sub} "${build}")" ]]; then
    make -j${nproc} "${MAKEVARS[@]}"
    make install "${MAKEVARS[@]}"
else
    make -j${nproc} all-host "${MAKEVARS[@]}"
    make install-host "${MAKEVARS[@]}"
fi

# Strip the debug info from the compiler (drivers, `cc1*`, `lto1`, the LTO plugin and
# `libcc1`), which is most of its size.  `-S` keeps the symbols that GCC plugins link
# against.  The target libraries in `${prefix}/${target}` and `lib/gcc/${target}` keep theirs.
is_object_file() {
    case "$(head -c4 "${1}" | od -An -tx1 | tr -d ' \n')" in
        # ELF, Mach-O (64-bit, 32-bit, universal), PE
        7f454c46|cffaedfe|cefaedfe|cafebabe|4d5a*) return 0 ;;
    esac
    return 1
}
for f in $(find ${prefix}/bin ${prefix}/libexec ${prefix}/lib*/libcc1* ${prefix}/lib/gcc/${target}/*/plugin \
                -maxdepth 4 -type f 2>/dev/null); do
    if is_object_file "${f}"; then
        ${HOST_STRIP} -S "${f}"
    fi
done

# Remove misleading libtool archives
rm -f ${prefix}/${target}/lib*/*.la

# Remove heavy doc directories
rm -rf ${prefix}/share/man

install_license ${WORKSPACE}/srcdir/gcc-*/COPYING*
"""

"""
    gcc_script(; preamble = "", extra_conf_args = String[])

The build script.  `preamble` runs before anything else (except for the MemorySanitizer
`libstdc++` build), e.g. to set compiler flags that an older GCC needs, and
`extra_conf_args` are passed to GCC's `configure`.
"""
function gcc_script(; preamble::AbstractString = "", extra_conf_args::Vector{<:AbstractString} = String[])
    script = gcc_script_base
    if !isempty(preamble)
        anchor = "\ncd \${WORKSPACE}/srcdir\n"
        @assert occursin(anchor, script)
        script = replace(script, anchor => string("\n", preamble, anchor); count=1)
    end
    if !isempty(extra_conf_args)
        anchor = "\n\$WORKSPACE/srcdir/gcc-*/configure"
        @assert occursin(anchor, script)
        script = replace(script, anchor => string("\nGCC_CONF_ARGS+=( ", join(extra_conf_args, " "), " )", anchor); count=1)
    end
    return script
end

# Cross compilers from each host to every target, plus a native compiler for each target.
# The compilers for hosts other than x86_64-linux-gnu are Canadian crosses: they can't run
# on the build machine, so they build no target libraries, and the target JLLs come from the
# x86_64-linux-gnu-hosted build of each target.
host_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
]
gcc_platforms(target_platforms = supported_platforms()) = vcat(
    [CrossPlatform(host => target) for host in host_platforms, target in target_platforms if host != target][:],
    [CrossPlatform(target => target) for target in target_platforms],
)

gcc_products = [
    FileProduct("bin", :bindir),
    ExecutableProduct("\${target}-gcc", :gcc),
    ExecutableProduct("\${target}-g++", :gxx),
]

# GCC is built for `host` with the bootstrap GCC, against the target's C library (and, on
# Linux, kernel headers), which is installed into `${target_prefix}/${target}` as GCC's
# build sysroot.  The target libraries are built with the new compiler (`xgcc`).
function gcc_build_spec_generator(host, platform)
    if sanitize(platform.target) == "memory"
        # The sanitized libstdc++ is built before any sanitized C++ runtime exists, so its
        # configure checks link against the plain libstdc++.
        return default_build_spec_generator(;
            target_toolchains = [CToolchain(; vendor=:clang, compiler_runtime=:libgcc, cxx_runtime=:unsanitized_libstdcxx)],
            host_toolchains = [CToolchain(), CMakeToolchain(), HostToolsToolchain()],
        )(host, platform.target)
    end
    target_str = triplet(gcc_platform(platform.target))

    target_sources = JLLSource[]
    if os(platform.target) == "linux"
        push!(target_sources, JLLSource("LinuxKernelHeaders_jll", platform.target;
                                        version=v"6.9.1", target=joinpath(target_str, "usr")))
    end
    if libc(platform.target) == "glibc"
        BBT = BinaryBuilder2.BinaryBuilderToolchains
        glibc_version = BBT.oldest_glibc_version(platform.target)
        push!(target_sources, JLLSource("Glibc_jll", platform.target;
                                        version=BBT.glibc_jll_versionspec(glibc_version),
                                        target=target_str))
    elseif libc(platform.target) == "musl"
        push!(target_sources, JLLSource("Musl_jll", platform.target; version=v"1.2.7", target=target_str))
    elseif Sys.iswindows(platform.target)
        push!(target_sources, JLLSource("Mingw_jll", platform.target; version=v"11.0.1", target=target_str))
    elseif Sys.isapple(platform.target)
        push!(target_sources, JLLSource("macOSSDK_jll", platform.target; version=v"11.1.1", target=target_str))
    elseif Sys.isfreebsd(platform.target)
        push!(target_sources, JLLSource("FreeBSDSysroot_jll", platform.target; version=v"14.1.0", target=target_str))
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
            [CToolchain(; vendor=:gcc_bootstrap, lock_microarchitecture=false)],
            target_sources,
            [],
            Set{Symbol}(),
        ),
    ]
end

function gcc_extract_spec_generator(build::BuildConfig, platform::AbstractPlatform)
    if sanitize(platform.target) == "memory"
        return libstdcxx_sanitized_extract_specs(build, platform)
    end
    gcc_crt_object_names = ["libgcc.a"]
    if Sys.isapple(platform.target)
        append!(gcc_crt_object_names, ["crttms.o", "crt3.o"])
    else
        append!(gcc_crt_object_names, ["crtbegin.o", "crtend.o"])
    end
    gcc_crt_object_products = [
        FileProduct([string(raw"lib/gcc/${target}/${gcc_version}/", name)],
                    Symbol(replace(name, "." => "_"))) for name in gcc_crt_object_names
    ]

    # GCC links the macOS SDK's `/usr/lib/libiconv.2.dylib`: libstdc++ (and the
    # sanitizer runtimes) when targeting macOS, and the compiler itself when running on it
    macos_audit_config = AuditConfig(; extra_system_libraries = ["libiconv.2.dylib"])
    target_audit_config = Sys.isapple(platform.target) ? macos_audit_config : nothing
    host_audit_config = Sys.isapple(platform.host) ? macos_audit_config : nothing

    host_spec = get_target_spec_by_name(build, "host")
    gcc_spec = ExtractSpec(
        raw"""
        # Everything not extracted into the target JLLs
        extract ${prefix}/**
        rm -rf ${extract_dir}/${target}/include
        rm -rf ${extract_dir}/${target}/${lib64}
        # Except for the plugin headers, which describe the host GCC runs on
        # (`GCC_crt_objects` is per target only, so it can't carry them)
        plugin_dir=lib/gcc/${target}/${gcc_version}/plugin
        if [[ -d ${extract_dir}/${plugin_dir} ]]; then
            mv ${extract_dir}/${plugin_dir} ${extract_dir}/gcc_plugin
        fi
        rm -rf ${extract_dir}/lib/gcc
        if [[ -d ${extract_dir}/gcc_plugin ]]; then
            mkdir -p $(dirname ${extract_dir}/${plugin_dir})
            mv ${extract_dir}/gcc_plugin ${extract_dir}/${plugin_dir}
        fi
        """,
        [
            ExecutableProduct("\${target}-gcc", :gcc),
            ExecutableProduct("\${target}-g++", :gxx),
        ],
        host_spec;
        # `GCC` doesn't depend on the target JLLs: they are not `CrossPlatform`s,
        # so JLLPrefixes would not install them alongside it anyway.
        jll_name = "GCC",
        platform,
        audit_config = host_audit_config,
    )

    # A Canadian cross builds no target libraries (see the build script)
    build_machine = get_target_spec_by_name(build, "build").platform.target
    if triplet(gcc_platform(platform.host)) != triplet(gcc_platform(build_machine))
        return ExtractSpec[gcc_spec]
    end

    return ExtractSpec[
        ExtractSpec(
            raw"""
            extract ${prefix}/${target}/include
            extract ${prefix}/${target}/${lib64}/libstdc++*
            """,
            [
                FileProduct([raw"${target}/include/c++/${gcc_version}/iostream"], :iostream),
                FileProduct([raw"${target}/${lib64}/libstdc++.a"], :libstdcxx_a),
                LibraryProduct([raw"${target}/${lib64}/libstdc++"], :libstdcxx),
            ],
            host_spec;
            jll_name = "libstdcxx",
            platform = platform.target,
            audit_config = target_audit_config,
        ),
        ExtractSpec(
            raw"""
            extract ${prefix}/${target}/${lib64}
            # `libstdc++` goes into `libstdcxx`
            rm -f ${extract_dir}/${target}/${lib64}/libstdc++*
            """,
            [
                LibraryProduct([
                        raw"${target}/${lib64}/libgcc_s",
                        # Windows names of libgcc_s
                        raw"${target}/${lib64}/libgcc_s_seh",
                        raw"${target}/${lib64}/libgcc_s_sjlj",
                    ],
                    :libgcc_s
                ),
            ],
            host_spec;
            jll_name = "GCC_support_libraries",
            platform = platform.target,
            audit_config = target_audit_config,
        ),
        ExtractSpec(
            raw"""
            extract ${prefix}/lib/gcc/${target}/${gcc_version}
            # The plugin headers describe the host GCC runs on, they go with `GCC`
            rm -rf ${extract_dir}/lib/gcc/${target}/${gcc_version}/plugin
            """,
            gcc_crt_object_products,
            host_spec;
            jll_name = "GCC_crt_objects",
            platform = platform.target,
        ),
        gcc_spec,
    ]
end

function libstdcxx_sanitized_extract_specs(build::BuildConfig, platform::AbstractPlatform)
    gcc_target = triplet(gcc_platform(platform.target))
    gcc_version = build.src_version
    return ExtractSpec[
        ExtractSpec(
            """
            extract \${prefix}/$(gcc_target)/include
            extract \${prefix}/$(gcc_target)/lib64/libstdc++*
            """,
            [
                FileProduct(["$(gcc_target)/include/c++/$(gcc_version)/iostream"], :iostream),
                FileProduct(["$(gcc_target)/lib64/libstdc++.a"], :libstdcxx_a),
                LibraryProduct(["$(gcc_target)/lib64/libstdc++"], :libstdcxx),
            ],
            get_default_target_spec(build);
            jll_name = "libstdcxx",
            platform = platform.target,
        ),
    ]
end
