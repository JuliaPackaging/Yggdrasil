using BinaryBuilder, BinaryBuilderBase, Base.BinaryPlatforms
include("../../fancy_toys.jl")

# Since we can build a variety of GCC versions, track them and their hashes here.
# We download GCC, MPFR, MPC, ISL and GMP.
const gcc_version_sources = Dict{VersionNumber,Vector}(
    v"4.8.5" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-4.8.5/gcc-4.8.5.tar.bz2",
                        "22fb1e7e0f68a63cee631d85b20461d1ea6bda162f03096350e38c8d427ecf23"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz",
                        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz",
                        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2",
                        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775"),
    ],
    v"5.2.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-5.2.0/gcc-5.2.0.tar.bz2",
                        "5f835b04b5f7dd4f4d2dc96190ec1621b8d89f2dc6f638f9f8bc1b1014ba8cad"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz",
                        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz",
                        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2",
                        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.14.tar.bz2",
                        "7e3c02ff52f8540f6a85534f54158968417fd676001651c8289c705bd0228f36"),
    ],
    v"6.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-6.1.0/gcc-6.1.0.tar.bz2",
                        "09c4c85cabebb971b1de732a0219609f93fc0af5f86f6e437fd8d7f832f1a351"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz",
                        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz",
                        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2",
                        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.15.tar.bz2",
                        "8ceebbf4d9a81afa2b4449113cee4b7cb14a687d7a549a963deb5e2a41458b6b"),
    ],
    v"7.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-7.1.0/gcc-7.1.0.tar.bz2",
                        "8a8136c235f64c6fef69cac0d73a46a1a09bb250776a050aec8f9fc880bebc17"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-3.1.4.tar.xz",
                        "761413b16d749c53e2bfd2b1dfaa3b027b0e793e404b90b5fbaeef60af6517f5"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.0.3.tar.gz",
                        "617decc6ea09889fb08ede330917a00b16809b8db88c29c31bfbb49cbf88ecc3"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2",
                        "412538bb65c799ac98e17e8cfcdacbb257a57362acfaaff254b0fcae970126d2"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.0.tar.xz",
                        "68dadacce515b0f8a54f510edf07c1b636492bcdb8e8d54c56eb216225d16989"),
    ],
    v"8.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-8.1.0/gcc-8.1.0.tar.xz",
                        "1d1866f992626e61349a1ccd0b8d5253816222cdc13390dcfaa74b093aa2b153"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.1.tar.xz",
                        "67874a60826303ee2fb6affc6dc0ddd3e749e9bfcb4c8655e3953d0458a6e16e"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                        "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                        "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                        "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"),
    ],
    v"9.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-9.1.0/gcc-9.1.0.tar.xz",
                        "79a66834e96a6050d8fe78db2c3b32fb285b230b855d0a66288235bc04b327a0"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.2.tar.xz",
                        "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                        "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                        "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                        "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"),
    ],
    v"10.2.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz",
                        "b8dd4368bb9c7f0b98188317ee0254dd8cc99d1e3a18d0ff146c855fe16c1d8c"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.2.tar.xz",
                        "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                        "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                        "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                        "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"),
    ],
    v"11.1.0" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/gcc/gcc-11.1.0/gcc-11.1.0.tar.xz",
                        "4c4a6fb8a8396059241c2e674b85b351c26a5d678274007f076957afa1cc9ddf"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.2.tar.xz",
                        "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a"),
        ArchiveSource("https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz",
                        "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"),
        ArchiveSource("https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2",
                        "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b"),
        ArchiveSource("https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz",
                        "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"),
    ],
)

const glibc_version_sources = Dict{VersionNumber,Vector}(
    v"2.12.2" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.12.2.tar.xz",
                        "0eb4fdf7301a59d3822194f20a2782858955291dd93be264b8b8d4d56f87203f"),
    ],
    v"2.17" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.17.tar.xz",
                        "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e"),
    ],
    v"2.19" => [
        ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.19.tar.xz",
                        "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2"),
    ],
)


function gcc_sources(gcc_version::VersionNumber, platform::AbstractPlatform)
    sources = [
        # First, the GCC version we're going to build
        gcc_version_sources[gcc_version]...,
        # Also, our patches
        DirectorySource("./bundled"; follow_symlinks=true),
    ]

    # We bundle together GCC, Binutils and libc.
    local glibc_version
    if libc(platform) == "glibc"
        if arch(platform) ∈ ("x86_64", "i686")
            glibc_version = v"2.12.2"
        elseif arch(platform) ∈ ("powerpc64le",)
            glibc_version = v"2.17"
        else
            glibc_version = v"2.19"
        end
        push!(sources, glibc_version_sources[glibc_version]...)
    end
    return sources
end

function gcc_script()
    return raw"""
    cd ${WORKSPACE}/srcdir

    # Figure out the GCC version from the directory name
    gcc_version="$(echo gcc-* | cut -d- -f2)"

    # GCC shouldn't ever use the target compilers, only the host compilers
    PATH=$(echo ${PATH} | tr ':' '\n' | grep -v ${target} | tr '\n' ':')
    unset gcc g++ cc cxx CC CXX

    # We do, however, need to provide some host tools without prefixes, apparently
    ln -s $(which ${HOSTAR}) $(dirname $(which ${HOSTAR}))/ar
    ln -s $(which ${HOSTCC}) $(dirname $(which ${HOSTAR}))/cc
    ln -s $(which ${HOSTCXX}) $(dirname $(which ${HOSTAR}))/c++

    # Some things need /lib64, others just need /lib
    case ${bb_target} in
        x86_64*)
            LIB64=lib64
            ;;
        aarch64*)
            LIB64=lib64
            ;;
        ppc64*)
            LIB64=lib64
            ;;
        *)
            LIB64=lib
            ;;
    esac

    # Update configure scripts for all projects
    update_configure_scripts

    # Force everything to default to cross compiling; this avoids differences
    # in behavior between when we target `x86_64-linux-musl`, for example, as
    # that is our host triplet.
    for f in $(find . -name configure); do
        sed -i.bak -e 's&cross_compiling=no&cross_compiling=yes&g' "${f}"
        sed -i.bak -e 's&is_cross_compiler=no&is_cross_compiler=yes&g' "${f}"
    done

    # Initialize GCC_CONF_ARGS
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
    fi

    # On musl targets, disable a bunch of things we don't want
    if [[ "${target}" == *-musl* ]]; then
        GCC_CONF_ARGS+=( --disable-libssp --disable-libmpx --disable-libmudflap )
        GCC_CONF_ARGS+=( --disable-libsanitizer --disable-symvers )
        export libat_cv_have_ifunc=no
        export ac_cv_have_decl__builtin_ffs=yes

        musl_arch()
        {
            case "${target}" in
                i686*)
                    echo i386 ;;
                arm*)
                    echo armhf ;;
                *)
                    echo ${target%%-*} ;;
            esac
        }

    elif [[ "${target}" == *-mingw* ]]; then
        # On mingw, we need to explicitly set the windres code page to 1, otherwise windres segfaults
        export CPPFLAGS="${CPPFLAGS} -DCP_ACP=1"

    elif [[ "${target}" == *-darwin* ]]; then
        # Use llvm archive tools to dodge binutils bugs
        export LD_FOR_TARGET=${prefix}/bin/${target}-ld
        export AS_FOR_TARGET=${prefix}/bin/llvm-as
        export AR_FOR_TARGET=${prefix}/bin/llvm-ar
        export NM_FOR_TARGET=${prefix}/bin/llvm-nm
        export RANLIB_FOR_TARGET=${prefix}/bin/llvm-ranlib

        # GCC build needs a little extra help finding our binutils
        GCC_CONF_ARGS+=( "--with-ld=${prefix}/bin/${target}-ld" )
        GCC_CONF_ARGS+=( "--with-as=${prefix}/bin/${target}-as" )

        # GCC doesn't turn LTO on by default for some reason.
        GCC_CONF_ARGS+=( --enable-lto --enable-plugin )

        # On darwin, cilk doesn't build on 5.X-7.X.  :(
        export enable_libcilkrts=no

        # GCC doesn't know how to use availability macros properly, so tell it not to use functions
        # that are available only starting in later macOS versions such as `clock_gettime` or `mkostemp`
        export ac_cv_func_clock_gettime=no
        export ac_cv_func_mkostemp=no
    fi

    # Link dependent packages into gcc build root:
    cd $WORKSPACE/srcdir/gcc-*/
    for proj in mpfr mpc isl gmp; do
        if [[ -d $(echo ../${proj}-*) ]]; then
            mv ../${proj}-* ${proj}
        fi
    done

    # Do not run fixincludes except on Darwin
    if [[ ${target} != *-darwin* ]]; then
        sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
    fi

    # Apply all gcc patches, if any exist
    if compgen -G "${WORKSPACE}/srcdir/patches/gcc-*.patch" > /dev/null; then
        for p in ${WORKSPACE}/srcdir/patches/gcc-*.patch; do
            atomic_patch -p1 "${p}"
        done
    fi

    # Build in separate directory
    mkdir -p $WORKSPACE/srcdir/gcc_build
    cd $WORKSPACE/srcdir/gcc_build

    # This is the "sysroot" that we've placed all our dependencies inside of
    sysroot="${prefix}/${target}"

    ## Platform-dependent arguments
    GCC_CONF_ARGS+=( --enable-languages=c,c++ )
    if [[ "$target" == *-darwin* ]]; then
        echo
    elif [[ "${target}" == *linux* ]]; then
        echo
    elif [[ "${target}" == *freebsd* ]]; then
        echo
    # On mingw32 override native system header directories
    elif [[ "${target}" == *mingw* ]]; then
        GCC_CONF_ARGS+=( --with-native-system-header-dir=/include )

        # On mingw, we need to explicitly enable openmp
        GCC_CONF_ARGS+=( --enable-libgomp )

        # We also need to symlink our lib directory specially
        ln -s sys-root/lib ${sysroot}/lib
    fi

    # GCC won't build (crti.o: no such file or directory) unless these directories exist.
    # They can be empty though.
    mkdir -p ${sysroot}/lib #${sysroot}/usr/lib
    $WORKSPACE/srcdir/gcc-*/configure \
        --prefix="${prefix}" \
        --target="${target}" \
        --host="${host}" \
        --build="${MACHTYPE}" \
        --with-build-sysroot="${sysroot}" \
        --with-sysroot="${sysroot}" \
        --with-gxx-include-dir="${sysroot}/include/c++/${gcc_version}" \
        --disable-multilib \
        --disable-werror \
        --enable-bootstrap \
        --enable-threads=posix \
        --program-prefix="${target}-" \
        ${GCC_CONF_ARGS[@]}

    ## Build, build, build!
    make -j ${nproc}
    make install

    # Remove misleading libtool archives
    rm -f ${prefix}/${target}/lib*/*.la

    # Remove heavy doc directories
    rm -rf ${prefix}/share/man
    """
end

function gcc_platforms(;
                        # We're going to build cross-compilers that can run from the following platforms:
                        cross_host_platforms = [
                           #Platform("x86_64", "linux"; libc="musl"),
                           Platform("x86_64", "linux"; libc="glibc"),
                        ],
                        # We're going to build compilers that can target the following platforms:
                        target_platforms = supported_platforms(;experimental=true))
    platforms_to_build = CrossPlatform[]

    # TODO: For now, only build for x86_64 glibc Linux
    filter!(p -> Sys.islinux(p) && libc(p) == "glibc", target_platforms)
    filter!(p -> Sys.islinux(p) && arch(p) == "x86_64", target_platforms)

    # Now, in a loop, add target platforms for cross and native compilers
    for target_platform in target_platforms
        # Add a target for this platform for each cross-host we want to build
        for host_platform in cross_host_platforms
            push!(platforms_to_build, CrossPlatform(host_platform => target_platform))
        end
        # Also add a native build
        if target_platform ∉ cross_host_platforms
            push!(platforms_to_build, CrossPlatform(target_platform))
        end
    end
    return platforms_to_build
end

# The products that we will ensure are always built
function gcc_products(platform)
    target = BinaryBuilderBase.aatriplet(platform.target)
    return Product[
        FileProduct("bin", :bindir),
        ExecutableProduct("$(target)-gcc", :gcc),
        ExecutableProduct("$(target)-g++", :gxx),
    ]
end

function gcc_dependencies(gcc_version::VersionNumber, platform::AbstractPlatform)
    # GCC likes to find things in `${prefix}/${triplet}`, so we place things
    # in the "target subdir" with the `prefix` Dependency attribute
    target_subdir = BinaryBuilderBase.aatriplet(platform.target)

    # Build up list of dependencies that we'll return
    dependencies = AbstractDependency[
        # GCC needs `Zlib_jll` in order to deal with compressed sections
        Dependency("Zlib_jll"),
    ]

    if Sys.islinux(platform)
        # Linux always requires the LinuxKernelHeaders_jll, and we want them in `${target}/usr`
        push!(dependencies, BuildDependency("LinuxKernelHeaders_jll"; prefix=joinpath(target_subdir, "usr")))

        # Add Binutils_jll, as that's definitely needed on Linux as well
        push!(dependencies, BuildDependency("Binutils_jll"))

        # Add different glibc versions depending on architecture
        local glibc_version
        if arch(platform) ∈ ("x86_64", "i686")
            glibc_version = v"2.12.2"
        elseif arch(platform) ∈ ("powerpc64le",)
            glibc_version = v"2.17"
        elseif arch(platform) ∈ ("armv7l", "armv6l", "aarch64")
            glibc_version = v"2.19"
        end
        push!(dependencies, BuildDependency(
            Pkg.Types.PackageSpec(;
                name="Glibc_jll",
                version=glibc_version,
            );
            prefix=target_subdir),
        )
    end

    return dependencies
end

# GCC is a horrifying beast, and the sources, dependencies, products, etc... all vary widely
# based on gcc version, platform, etc...  To simplify this mess, we define here a generator
# function that emits the various sets of metadata necessary to pass to `build_tarballs()`.
function gcc_metadata(gcc_versions = [], platforms = gcc_platforms())
    if !isa(gcc_version, Vector)
        gcc_versions = [gcc_versions]
    end

    metadata = []
    for gcc_version in gcc_versions
        for platform in platforms
            push!(metadata, (
                gcc_sources(gcc_version, platform),
                gcc_script(),
                [platform],
                gcc_products(platform),
                gcc_dependencies(gcc_version, platform),
            ))
        end
    end
    return metadata
end
