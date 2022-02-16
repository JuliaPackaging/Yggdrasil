using BinaryBuilder, BinaryBuilderBase, Base.BinaryPlatforms
include("../../fancy_toys.jl")

function gcc_sources(gcc_version::VersionNumber)
    # Since we can build a variety of GCC versions, track them and their hashes here.
    # We download GCC, MPFR, MPC, ISL and GMP.
    gcc_version_sources = Dict{VersionNumber,Vector}(
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

    # We bundle together GCC, Binutils and libc.
    return [
        gcc_version_sources[gcc_version]...,
        DirectorySource("./bundled"; follow_symlinks=true),
    ]
end

function gcc_script()
    return string(bash_parse_encoded_target_triplet(),
    raw"""
    cd ${WORKSPACE}/srcdir

    # Some things need /lib64, others just need /lib
    case ${encoded_target} in
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
    if [[ "${encoded_target}" == arm*hf ]]; then
        # We choose the armv6 arch by default for compatibility
        GCC_CONF_ARGS+=( --with-float=hard --with-arch=armv6 --with-fpu=vfp )
    elif [[ "${encoded_target}" == x86_64* ]]; then
        GCC_CONF_ARGS+=( --with-arch=x86-64 )
    elif [[ "${encoded_target}" == i686* ]]; then
        GCC_CONF_ARGS+=( --with-arch=pentium4 )
    fi

    # On musl targets, disable a bunch of things we don't want
    if [[ "${encoded_target}" == *-musl* ]]; then
        GCC_CONF_ARGS+=( --disable-libssp --disable-libmpx --disable-libmudflap )
        GCC_CONF_ARGS+=( --disable-libsanitizer --disable-symvers )
        export libat_cv_have_ifunc=no
        export ac_cv_have_decl__builtin_ffs=yes

        musl_arch()
        {
            case "${encoded_target}" in
                i686*)
                    echo i386 ;;
                arm*)
                    echo armhf ;;
                *)
                    echo ${encoded_target%%-*} ;;
            esac
        }

    elif [[ "${encoded_target}" == *-mingw* ]]; then
        # On mingw, we need to explicitly set the windres code page to 1, otherwise windres segfaults
        export CPPFLAGS="${CPPFLAGS} -DCP_ACP=1"

    elif [[ "${encoded_target}" == *-darwin* ]]; then
        # Use llvm archive tools to dodge binutils bugs
        export LD_FOR_TARGET=${prefix}/bin/${encoded_target}-ld
        export AS_FOR_TARGET=${prefix}/bin/llvm-as
        export AR_FOR_TARGET=${prefix}/bin/llvm-ar
        export NM_FOR_TARGET=${prefix}/bin/llvm-nm
        export RANLIB_FOR_TARGET=${prefix}/bin/llvm-ranlib

        # GCC build needs a little extra help finding our binutils
        GCC_CONF_ARGS+=( "--with-ld=${prefix}/bin/${encoded_target}-ld" )
        GCC_CONF_ARGS+=( "--with-as=${prefix}/bin/${encoded_target}-as" )

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
    if [[ ${encoded_target} != *-darwin* ]]; then
        sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
    fi

    # Apply all gcc patches, if any exist
    if compgen -G "${WORKSPACE}/srcdir/patches/gcc-*.patch" > /dev/null; then
        for p in ${WORKSPACE}/srcdir/patches/gcc-*.patch; do
            atomic_patch -p1 "${p}"
        done
    fi

    # Back to GCC-land, build brand new full compiler
    mkdir -p $WORKSPACE/srcdir/gcc_build
    cd $WORKSPACE/srcdir/gcc_build

    # This is the "sysroot" that we've placed all our dependencies inside of
    sysroot="${prefix}/${encoded_target}"

    ## Platform-dependent arguments
    if [[ "$encoded_target" == *-darwin* ]]; then
        GCC_CONF_ARGS+=( --enable-languages=c,c++ )

    elif [[ "${encoded_target}" == *linux* ]]; then
        GCC_CONF_ARGS+=( --enable-languages=c,c++ )

    elif [[ "${encoded_target}" == *freebsd* ]]; then
        GCC_CONF_ARGS+=( --enable-languages=c,c++ )

    # On mingw32 override native system header directories
    elif [[ "${encoded_target}" == *mingw* ]]; then
        GCC_CONF_ARGS+=( --enable-languages=c,c++ )
        GCC_CONF_ARGS+=( --with-native-system-header-dir=/include )

        # On mingw, we need to explicitly enable openmp
        GCC_CONF_ARGS+=( --enable-libgomp )

        # We also need to symlink our lib directory specially
        ln -s sys-root/lib ${sysroot}/lib
    fi

    # GCC won't build (crti.o: no such file or directory) unless these directories exist.
    # They can be empty though.
    mkdir -p ${sysroot}/lib ${sysroot}/usr/lib

    # Notes about flags:
    # `--with-native-system-header-dir``: should look like an absolute path, but is concatenated to `--with-sysroot`.
    $WORKSPACE/srcdir/gcc-*/configure \
        --prefix="/usr" \
        --with-build-sysroot="${sysroot}" \
        --with-sysroot="${sysroot}" \
        --target="${encoded_target}" \
        --host="${MACHTYPE}" \
        --build="${MACHTYPE}" \
        --disable-multilib \
        --disable-werror \
        --disable-bootstrap \
        --enable-shared \
        --enable-host-shared \
        --enable-threads=posix \
        --program-prefix="${encoded_target}-" \
        ${GCC_CONF_ARGS[@]}

    ## Build, build, build!
    make -j ${nproc} CPP="$(which cpp)"
    make DESTDIR="${prefix}" install

    # Remove misleading libtool archives
    rm -f ${prefix}/${encoded_target}/lib*/*.la

    # Remove heavy doc directories
    rm -rf ${prefix}/usr/share/man
    """)
end

function gcc_platforms()
    #return encode_target_platform.(supported_platforms(;experimental=true))
    return encode_target_platform.([Platform("aarch64", "linux")])
end

# The products that we will ensure are always built
function gcc_products()
    return Product[
        FileProduct("bin", :bindir),
        # Normally, we would want to provide these, but since we are claiming an incorrect
        # platform (e.g. we claim this is for `compiler_target` but it's really for `host_platform`,
        # which we do because we need the appropriate `platofrm_support`) it doesn't find them.
        # We just build with no products for now.
        #ExecutableProduct("\${target}-gcc", :gcc),
        #ExecutableProduct("\${target}-g++", :gxx),
    ]
end

function gcc_dependencies()
    return AbstractDependency[
        BuildDependency("LinuxKernelHeaders_jll"),
        BuildDependency("Binutils_jll"),
        Dependency("Zlib_jll"),
        BuildDependency(Pkg.Types.PackageSpec(;name="Glibc_jll", version=v"2.12.2")),
    ]
end