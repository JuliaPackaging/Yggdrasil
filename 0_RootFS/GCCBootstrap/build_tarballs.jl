using BinaryBuilder
include("../common.jl")

# Bootstrapping ahoy!
Core.eval(BinaryBuilder, :(bootstrap_list = [:rootfs, :platform_support]))

# We'll build this version of GCC
version_idx = findfirst(x -> startswith(x, "--gcc-version"), ARGS)
if version_idx == nothing
    error("This is not a typical build_tarballs.jl!  Must provide gcc version; e.g. --gcc-version 5.2.0")
end
gcc_version = VersionNumber(ARGS[version_idx+1])
deleteat!(ARGS, (version_idx, version_idx+1))

compiler_target = platform_key_abi(ARGS[end])
if isa(compiler_target, UnknownPlatform)
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))
name = "GCCBootstrap"

# Since we can build a variety of GCC versions, track them and their hashes here.
# We download GCC, MPFR, MPC, ISL and GMP.
gcc_version_sources = Dict(
    v"4.8.5" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-4.8.5/gcc-4.8.5.tar.bz2" =>
        "22fb1e7e0f68a63cee631d85b20461d1ea6bda162f03096350e38c8d427ecf23",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz" =>
        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b",
        "https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz" =>
        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4",
        "https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2" =>
        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775",
    ],
    v"5.2.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-5.2.0/gcc-5.2.0.tar.bz2" =>
        "5f835b04b5f7dd4f4d2dc96190ec1621b8d89f2dc6f638f9f8bc1b1014ba8cad",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz" =>
        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b",
        "https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz" =>
        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4",
        "https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2" =>
        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.14.tar.bz2" =>
        "7e3c02ff52f8540f6a85534f54158968417fd676001651c8289c705bd0228f36",
    ],
    v"6.1.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-6.1.0/gcc-6.1.0.tar.bz2" =>
        "09c4c85cabebb971b1de732a0219609f93fc0af5f86f6e437fd8d7f832f1a351",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-2.4.2.tar.xz" =>
        "d7271bbfbc9ddf387d3919df8318cd7192c67b232919bfa1cb3202d07843da1b",
        "https://gcc.gnu.org/pub/gcc/infrastructure/mpc-0.8.1.tar.gz" =>
        "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4",
        "https://mirrors.kernel.org/gnu/gmp/gmp-4.3.2.tar.bz2" =>
        "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.15.tar.bz2" =>
        "8ceebbf4d9a81afa2b4449113cee4b7cb14a687d7a549a963deb5e2a41458b6b",
    ],
    v"7.1.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-7.1.0/gcc-7.1.0.tar.bz2" =>
        "8a8136c235f64c6fef69cac0d73a46a1a09bb250776a050aec8f9fc880bebc17",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-3.1.4.tar.xz" =>
        "761413b16d749c53e2bfd2b1dfaa3b027b0e793e404b90b5fbaeef60af6517f5",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.0.3.tar.gz" =>
        "617decc6ea09889fb08ede330917a00b16809b8db88c29c31bfbb49cbf88ecc3",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2" =>
        "412538bb65c799ac98e17e8cfcdacbb257a57362acfaaff254b0fcae970126d2",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.1.0.tar.xz" =>
        "68dadacce515b0f8a54f510edf07c1b636492bcdb8e8d54c56eb216225d16989",
    ],
    v"8.1.0" => [
        "https://mirrors.kernel.org/gnu/gcc/gcc-8.1.0/gcc-8.1.0.tar.xz" =>
        "1d1866f992626e61349a1ccd0b8d5253816222cdc13390dcfaa74b093aa2b153",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-4.0.1.tar.xz" =>
        "67874a60826303ee2fb6affc6dc0ddd3e749e9bfcb4c8655e3953d0458a6e16e",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.1.0.tar.gz" =>
        "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e",
        "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2" =>
        "6b8b0fd7f81d0a957beb3679c81bbb34ccc7568d5682844d8924424a0dadcb1b",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.1.2.tar.xz" =>
        "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912",
    ],
)


# Map from GCC version and platform -> binutils sources
if isa(compiler_target, MacOS)
    # MacOS doesn't actually use binutils, it uses cctools
    binutils_sources = [
        "https://github.com/tpoechtrager/apple-libtapi.git" =>
        "3efb201881e7a76a21e0554906cf306432539cef",
        "https://github.com/tpoechtrager/cctools-port.git" =>
        "a2e02aad90a98ac034b8d0286496450d136ebfcd",
    ]
else
    # Different versions of GCC should be pared with different versions of Binutils
    binutils_gcc_version_mapping = Dict(
        v"4.8.5" => v"2.24",
        v"5.2.0" => v"2.25.1",
        v"6.1.0" => v"2.26",
        v"7.1.0" => v"2.27",
        v"8.1.0" => v"2.31",
    )

    # Everyone else uses GNU Binutils, but we have to version carefully.
    binutils_version_sources = Dict(
        v"2.24" => [
            "https://ftp.gnu.org/gnu/binutils/binutils-2.24.tar.bz2" =>
            "e5e8c5be9664e7f7f96e0d09919110ab5ad597794f5b1809871177a0f0f14137",
        ],
        v"2.25.1" => [
            "https://ftp.gnu.org/gnu/binutils/binutils-2.25.1.tar.bz2" =>
            "b5b14added7d78a8d1ca70b5cb75fef57ce2197264f4f5835326b0df22ac9f22",
        ],
        v"2.26" => [
            "https://ftp.gnu.org/gnu/binutils/binutils-2.26.tar.bz2" =>
            "c2ace41809542f5237afc7e3b8f32bb92bc7bc53c6232a84463c423b0714ecd9",
        ],
        v"2.27" => [
            "https://ftp.gnu.org/gnu/binutils/binutils-2.27.tar.bz2" =>
            "369737ce51587f92466041a97ab7d2358c6d9e1b6490b3940eb09fb0a9a6ac88",
        ],
        v"2.31" => [
            "https://ftp.gnu.org/gnu/binutils/binutils-2.31.tar.bz2" =>
            "2c49536b1ca6b8900531b9e34f211a81caf9bf85b1a71f82b81ae32fcd8ffe19",
        ],
    )
    binutils_version = binutils_gcc_version_mapping[gcc_version]
    binutils_sources = binutils_version_sources[binutils_version]
end


if isa(compiler_target, Linux) && libc(compiler_target) == :glibc
    # Depending on our architecture, we choose different versions of glibc
    if arch(compiler_target) in [:x86_64, :i686]
        libc_sources = [
            "https://mirrors.kernel.org/gnu/glibc/glibc-2.12.2.tar.xz" =>
            "0eb4fdf7301a59d3822194f20a2782858955291dd93be264b8b8d4d56f87203f",
        ]
    elseif arch(compiler_target) in [:armv7l, :aarch64]
        libc_sources = [
            "https://mirrors.kernel.org/gnu/glibc/glibc-2.19.tar.xz" =>
            "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2",
        ]
    elseif arch(compiler_target) in [:powerpc64le]
        libc_sources = [
            "https://mirrors.kernel.org/gnu/glibc/glibc-2.25.tar.xz" =>
            "067bd9bb3390e79aa45911537d13c3721f1d9d3769931a30c2681bfee66f23a0",
        ]
    else
        error("Unknown arch for glibc for compiler target $(compiler_target)")
    end
elseif isa(compiler_target, Linux) && libc(compiler_target) == :musl
    libc_sources = [
        "https://www.musl-libc.org/releases/musl-1.1.19.tar.gz" =>
        "db59a8578226b98373f5b27e61f0dd29ad2456f4aa9cec587ba8c24508e4c1d9",
    ]
elseif isa(compiler_target, MacOS)
    libc_sources = [
        "https://github.com/phracker/MacOSX-SDKs/releases/download/10.13/MacOSX10.10.sdk.tar.xz" =>
        "4a08de46b8e96f6db7ad3202054e28d7b3d60a3d38cd56e61f08fb4863c488ce",
    ]
elseif isa(compiler_target, FreeBSD)
    libc_sources = [
        "https://download.freebsd.org/ftp/releases/amd64/11.2-RELEASE/base.txz" =>
        "a002be690462ad4f5f2ada6d01784836946894ed9449de6289b3e67d8496fd19",
    ]
elseif isa(compiler_target, Windows)
    libc_sources = [
        "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v6.0.0.tar.bz2" =>
        "805e11101e26d7897fce7d49cbb140d7bac15f3e085a91e0001e80b2adaf48f0",
    ]
else
    error("Unknown libc mapping for platform $(compiler_target)")
end

# We bundle together GCC, Binutils and libc.
sources = [
    gcc_version_sources[gcc_version]...,
    binutils_sources...,
    libc_sources...,
    "./bundled",
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Bash recipe for building across all platforms
script  = "COMPILER_TARGET=$(triplet(compiler_target))\n"
script *= "HOST_TARGET=$(triplet(host_platform))\n"
script *= raw"""
cd ${WORKSPACE}/srcdir

# Install `gcc` from `apk`, which we'll use to bootstrap ourselves a BETTER `gcc`
apk add build-base gettext-dev gcc-objc clang

# We like to refer to things with their full triplets, so symlink our host tools
# (which have no prefix) to have the machtype prefix.
for tool in gcc g++ ar as ld lipo ranlib nm strip objcopy objdump readelf; do
	if [[ -f /usr/bin/${tool} ]]; then
		ln -s /usr/bin/${tool} /usr/bin/${HOST_TARGET}-${tool}
	fi
done

# Default sysroot
sysroot="${prefix}/${COMPILER_TARGET}/sys-root"
cp -ra "/opt/${COMPILER_TARGET}/${COMPILER_TARGET}" "${prefix}/${COMPILER_TARGET}"

# Some things need /lib64, others just need /lib
case ${COMPILER_TARGET} in
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

# Force everything to default to cross compiling!
for f in $(find . -name configure); do
    sed -i.bak -e 's&cross_compiling=no&cross_compiling=yes&g' "${f}"
    sed -i.bak -e 's&is_cross_compiler=no&is_cross_compiler=yes&g' "${f}"
done

# Allow us to run our binutils stuff as soon as it's ready
export PATH=${prefix}/bin:$PATH

# Initialize GCC_CONF_ARGS
GCC_CONF_ARGS=""

## Architecture-dependent arguments
# On arm*hf targets, pass --with-float=hard explicitly, and choose a default arch.
if [[ "${COMPILER_TARGET}" == arm*hf ]]; then
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-float=hard --with-arch=armv7-a --with-fpu=vfpv3-d16"
elif [[ "${COMPILER_TARGET}" == x86_64* ]]; then
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-arch=core2"
elif [[ "${COMPILER_TARGET}" == i686* ]]; then
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-arch=pentium4"
fi

# On musl targets, disable a bunch of things we don't want
if [[ "${COMPILER_TARGET}" == *-musl* ]]; then
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --disable-libssp --disable-libmpx --disable-libmudflap"
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --disable-libsanitizer --disable-symvers"
    export libat_cv_have_ifunc=no
    export ac_cv_have_decl__builtin_ffs=yes

    musl_arch()
    {
        case "${COMPILER_TARGET}" in
            i686*)
                echo i386 ;;
            arm*)
                echo armhf ;;
            *)
                echo ${COMPILER_TARGET%%-*} ;;
        esac
    }

elif [[ "${COMPILER_TARGET}" == *-mingw* ]]; then
    # On mingw, we need to explicitly set the windres code page to 1, otherwise windres segfaults
    export CPPFLAGS="${CPPFLAGS} -DCP_ACP=1"

elif [[ "${COMPILER_TARGET}" == *-darwin* ]]; then
    # Use llvm archive tools to dodge binutils bugs
    export LD_FOR_TARGET=${prefix}/bin/${COMPILER_TARGET}-ld
    export AR_FOR_TARGET=${prefix}/bin/llvm-ar
    export NM_FOR_TARGET=${prefix}/bin/llvm-nm
    export RANLIB_FOR_TARGET=${prefix}/bin/llvm-ranlib
    
    # GCC build doesn't pay attention to DSYMUTIL or DSYMUTIL_FOR_TARGET, tsk tsk
    mkdir -p ${prefix}/bin
    ln -s llvm-dsymutil ${prefix}/bin/dsymutil

    # GCC build needs a little exdtra help finding our binutils
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-ld=${prefix}/bin/${COMPILER_TARGET}-ld"
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-as=${prefix}/bin/${COMPILER_TARGET}-as"

    # On darwin, cilk doesn't build on 5.X-7.X.  :(
    export enable_libcilkrts=no
fi

# Link dependent packages into gcc build root:
cd $WORKSPACE/srcdir/gcc-*/
for proj in mpfr mpc isl gmp; do
    if [[ -d $(echo ../${proj}-*) ]]; then
        mv ../${proj}-* ${proj}
    fi
done

# Do not run fixincludes
sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in

# Apply all gcc patches
for p in ${WORKSPACE}/srcdir/patches/gcc*.patch; do
    atomic_patch -p1 "${p}" || true
done


# If we're on MacOS, we need to install cctools first, separately.
if [[ ${COMPILER_TARGET} == *-darwin* ]]; then
    cd ${WORKSPACE}/srcdir/apple-libtapi
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/libtapi_fullyaml.patch"

    mkdir -p ${WORKSPACE}/srcdir/apple-libtapi/build
    cd ${WORKSPACE}/srcdir/apple-libtapi/build

    export TAPIDIR=${WORKSPACE}/srcdir/apple-libtapi

    # Install libtapi
    cmake ../src/llvm \
        -DCMAKE_CXX_FLAGS="-I${TAPIDIR}/src/llvm/projects/clang/include -I${TAPIDIR}/build/projects/clang/include" \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DCMAKE_BUILD_TYPE=RELEASE \
        -DCMAKE_INSTALL_PREFIX=${prefix}
    make -j${nproc} VERBOSE=1 clangBasic
    make -j${nproc} VERBOSE=1
    make install

    # Install cctools
    mkdir -p ${WORKSPACE}/srcdir/cctools_build
    cd ${WORKSPACE}/srcdir/cctools_build
    CC=/usr/bin/clang CXX=/usr/bin/clang++ LDFLAGS=-L/usr/lib ${WORKSPACE}/srcdir/cctools-port/cctools/configure \
        --prefix=${prefix} \
        --target=${COMPILER_TARGET} \
        --host=${MACHTYPE} \
        --with-libtapi=${prefix}
    make -j${nproc}
    make install

# Otherwise, we need to install binutils first
else
    # We also need to build binutils
    cd ${WORKSPACE}/srcdir/binutils-*
    
    # Patch for building binutils 2.30+ against FreeBSD
    atomic_patch -p1 $WORKSPACE/srcdir/patches/binutils_freebsd_symbol_versioning.patch || true

    ./configure --prefix=${prefix} \
        --target=${COMPILER_TARGET} \
        --host=${MACHTYPE} \
        --with-sysroot="${sysroot}" \
        --enable-multilib \
        --program-prefix="${COMPILER_TARGET}-" \
        --disable-werror

    make -j${nproc}
    make install
fi


# GCC won't build (crti.o: no such file or directory) unless these directories exist.
# They can be empty though.
mkdir -p ${sysroot}/lib ${sysroot}/usr/lib

# Build bootstrap compiler in a separate directory
mkdir -p $WORKSPACE/srcdir/gcc_stage1
cd $WORKSPACE/srcdir/gcc_stage1

# Since this stage1 compiler is just going to be used to
# bootstrap, compile without many optimizations, which reduces
# overall build time
$WORKSPACE/srcdir/gcc-*/configure \
    --prefix="${prefix}" \
    --target="${COMPILER_TARGET}" \
    --host="${MACHTYPE}" \
    --build="${MACHTYPE}" \
    --disable-multilib \
    --disable-werror \
    --disable-decimal-float \
    --disable-threads \
    --disable-libatomic \
    --disable-libffi \
    --disable-libitm \
    --disable-libmudflap \
    --disable-libssp \
    --disable-libsanitizer \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libstdcxx \
    --without-headers \
    --disable-bootstrap \
    --enable-host-shared \
    --with-sysroot="${sysroot}" \
    --program-prefix="${COMPILER_TARGET}-" \
    --enable-languages="c" \
    ${GCC_CONF_ARGS}

make -j${nproc} all-gcc
make -j${nproc} install-gcc

unset CFLAGS
unset CXXFLAGS

# This is needed for any glibc older than 2.14, which includes the following commit
# https://sourceware.org/git/?p=glibc.git;a=commit;h=95f5a9a866695da4e038aa4e6ccbbfd5d9cf63b7
ln -vs libgcc.a $(${COMPILER_TARGET}-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/') || true

# Build libc (stage 1)
if [[ ${COMPILER_TARGET} == *-gnu* ]]; then
    # patch glibc
    cd ${WORKSPACE}/srcdir/glibc-*
    # patch glibc to keep around libgcc_s_resume on arm
    # ref: https://sourceware.org/ml/libc-alpha/2014-05/msg00573.html
    atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_arm_gcc_fix.patch || true

    # patch glibc's stupid gcc version check (we don't require this one, as if
    # it doesn't apply cleanly, it's probably fine)
    atomic_patch -p0 $WORKSPACE/srcdir/patches/glibc_gcc_version.patch || true
    atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_make_version.patch || true

    # patch older glibc's 32-bit assembly to withstand __i686 definition of
    # newer GCC's.  ref: http://comments.gmane.org/gmane.comp.lib.glibc.user/758
    atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_i686_asm.patch || true

    # Patch glibc's sunrpc cross generator to work with musl
    # See https://sourceware.org/bugzilla/show_bug.cgi?id=21604
    atomic_patch -p0 $WORKSPACE/srcdir/patches/glibc_sunrpc.patch || true

    # patch for building old glibc on newer binutils
    # These patches don't apply on those versions of glibc where they
    # are not needed, but that's ok.
    atomic_patch -p0 $WORKSPACE/srcdir/patches/glibc_nocommon.patch || true
    atomic_patch -p0 $WORKSPACE/srcdir/patches/glibc_regexp_nocommon.patch || true

    # patch for avoiding linking in musl libs for a glibc-linked binary
    atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_musl_rejection.patch || true
    atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_musl_rejection_old.patch || true

    # Patch for building glibc 2.25-2.30 on aarch64
    atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_aarch64_relocation.patch || true

    # Configure glibc
    mkdir ${WORKSPACE}/srcdir/glibc_build
    cd ${WORKSPACE}/srcdir/glibc_build
    ${WORKSPACE}/srcdir/glibc-*/configure \
        --prefix=/usr \
        --host=${COMPILER_TARGET} \
        --with-headers="${sysroot}/usr/include" \
        --disable-multilib \
        --disable-werror \
        libc_cv_forced_unwind=yes \
        libc_cv_c_cleanup=yes

    # Install headers
    mkdir -p ${prefix}/${COMPILER_TARGET}/include/gnu
    touch ${prefix}/${COMPILER_TARGET}/include/gnu/stubs.h
    mkdir -p ${sysroot}/usr/include/bits
    touch ${sysroot}/usr/include/bits/stdio_lim.h
    make install_root=${sysroot} install-bootstrap-headers=yes install-headers

    # Install CSU
    make csu/subdir_lib -j${nproc}
    mkdir -p ${sysroot}/usr/${LIB64}
    install csu/crt1.o csu/crti.o csu/crtn.o ${sysroot}/usr/${LIB64}
    ${COMPILER_TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${sysroot}/usr/${LIB64}/libc.so

elif [[ ${COMPILER_TARGET} == *-musl* ]]; then
    # Configure musl
    mkdir -p ${WORKSPACE}/srcdir/musl_build
    cd ${WORKSPACE}/srcdir/musl_build
    LDFLAGS="-Wl,-soname,libc.musl-$(musl_arch).so.1" ${WORKSPACE}/srcdir/musl-*/configure \
        --prefix=/usr \
        --host=${COMPILER_TARGET} \
        --with-headers="${sysroot}/usr/include" \
        --with-binutils=${prefix}/bin \
        --disable-multilib \
        --disable-werror \
        --enable-optimize \
        --enable-debug \
        CROSS_COMPILE="${COMPILER_TARGET}-"

    # Install headers
    make install-headers DESTDIR=${sysroot}
    
    # Make CRT
    make lib/{crt1,crti,crtn}.o
    mkdir -p ${sysroot}/usr/lib
    install lib/crt1.o lib/crti.o lib/crtn.o ${sysroot}/usr/lib
    ${COMPILER_TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${sysroot}/usr/lib/libc.so

elif [[ ${COMPILER_TARGET} == *-mingw* ]]; then
    # Build CRT
    mkdir -p $WORKSPACE/srcdir/mingw_crt_build
    cd $WORKSPACE/srcdir/mingw_crt_build
    MINGW_CONF_ARGS=""

    # If we're building a 32-bit build of mingw, add `--disable-lib64`
    if [[ "${COMPILER_TARGET}" == i686-* ]]; then
        MINGW_CONF_ARGS="${MINGW_CONF_ARGS} --disable-lib64"
    else
        MINGW_CONF_ARGS="${MINGW_CONF_ARGS} --disable-lib32"
    fi

    ${WORKSPACE}/srcdir/mingw-*/mingw-w64-crt/configure \
        --prefix=/ \
        --host=${COMPILER_TARGET} \
        --with-sysroot=${sysroot} \
        ${MINGW_CONF_ARGS}
    make -j${nproc} 
    make install DESTDIR=${sysroot}

elif [[ ${COMPILER_TARGET} == *-darwin* ]]; then
    # Install Darwin libc
    cd ${WORKSPACE}/srcdir/MacOSX*.sdk
    mkdir -p "${sysroot}"
    rsync -a usr "${sysroot}/"

elif [[ ${COMPILER_TARGET} == *freebsd* ]]; then
    cd ${WORKSPACE}/srcdir
    # We're going to clean out vestiges of libgcc_s and friends,
    # because we're going to compile our own from scratch
    for lib in gcc_s ssp; do
        find usr/ -name lib${lib}.\* -delete
        find lib/ -name lib${lib}.\* -delete
    done

    mkdir -p "${sysroot}/usr/lib"
    mv usr/lib/* "${sysroot}/usr/lib/"
    mv lib/* "${sysroot}/lib/"

    # Many symlinks exist that point to `../../lib/libfoo.so`.
    # We need them to point to just `libfoo.so`. :P
    for f in $(find "${prefix}/${COMPILER_TARGET}" -xtype l); do
        link_target="$(readlink "$f")"
        if [[ -n $(echo "${link_target}" | grep "^../../lib") ]]; then
            ln -vsf "${link_target#../../lib/}" "${f}"
        fi
    done
fi


# Back to GCC-land, install libgcc
cd ${WORKSPACE}/srcdir/gcc_stage1
make all-target-libgcc -j ${nproc}
make install-target-libgcc

# Finish off libc
if [[ ${COMPILER_TARGET} == *-gnu* ]]; then
    cd ${WORKSPACE}/srcdir/glibc_build
    make -j${nproc}
    make install install_root=${sysroot}

elif [[ ${COMPILER_TARGET} == *-musl* ]]; then
    # Re-configure musl to pick up our newly-built libgcc
    cd ${WORKSPACE}/srcdir/musl_build
    rm -rf *

    LDFLAGS="-Wl,-soname,libc.musl-$(musl_arch).so.1" ${WORKSPACE}/srcdir/musl-*/configure \
        --prefix=/usr \
        --host=${COMPILER_TARGET} \
        --with-headers="${sysroot}/usr/include" \
        --with-binutils=${prefix}/bin \
        --disable-multilib \
        --disable-werror \
        --enable-optimize \
        --enable-debug \
        CROSS_COMPILE="${COMPILER_TARGET}-"

    make -j${nproc} DESTDIR=${sysroot}
    rm -f ${sysroot}/usr/lib/libc.so
    make install DESTDIR=${sysroot}

    # Fix broken symlink
    ln -fsv ../usr/lib/libc.so ${sysroot}/lib/ld-musl-$(musl_arch).so.1

elif [[ ${COMPILER_TARGET} == *-mingw* ]]; then    
    cd $WORKSPACE/srcdir/mingw_crt_build

    # Build winpthreads
    mkdir -p $WORKSPACE/srcdir/mingw_winpthreads_build
    cd $WORKSPACE/srcdir/mingw_winpthreads_build
    ${WORKSPACE}/srcdir/mingw-*/mingw-w64-libraries/winpthreads/configure \
        --prefix=/ \
        --host=${COMPILER_TARGET} \
        --enable-static \
        --enable-shared

    make -j${nproc}
    make install DESTDIR=${sysroot}
fi

# Back to GCC-land, build brand new full compiler
mkdir -p $WORKSPACE/srcdir/gcc_build
cd $WORKSPACE/srcdir/gcc_build

## Platform-dependent arguments
if [[ "$COMPILER_TARGET" == *-darwin* ]]; then
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --enable-languages=c,c++,fortran,objc,obj-c++"

elif [[ "${COMPILER_TARGET}" == *linux* ]]; then
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --enable-languages=c,c++,fortran,objc,obj-c++"

elif [[ "${COMPILER_TARGET}" == *freebsd* ]]; then
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --enable-languages=c,c++,fortran"
   
# On mingw32 override native system header directories
elif [[ "${COMPILER_TARGET}" == *mingw* ]]; then
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --enable-languages=c,c++,fortran"
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-native-system-header-dir=/include"

    # On mingw, we need to explicitly enable openmp
    GCC_CONF_ARGS="${GCC_CONF_ARGS} --enable-libgomp"

    # We also need to symlink our lib directory specially
    ln -s sys-root/lib ${prefix}/${COMPILER_TARGET}/lib
fi

# GCC won't build (crti.o: no such file or directory) unless these directories exist.
# They can be empty though.
mkdir -p ${prefix}/${COMPILER_TARGET}/sys-root/{lib,usr/lib}

# We have to be really assertive with `CC`, `CC_FOR_BUILD` and `CC_FOR_TARGET`
# here, as if we don't, building for x86_64-linux-musl itself can fail, due to
# it getting confused between the compiler we just built and the host compiler.
CC=/usr/bin/gcc CC_FOR_BUILD=/usr/bin/gcc CC_FOR_TARGET=${prefix}/bin/${COMPILER_TARGET}-gcc $WORKSPACE/srcdir/gcc-*/configure \
    --prefix="${prefix}" \
    --target="${COMPILER_TARGET}" \
    --host="${MACHTYPE}" \
    --build="${MACHTYPE}" \
    --disable-multilib \
    --disable-werror \
    --enable-shared \
    --enable-host-shared \
    --enable-threads=posix \
    --with-sysroot="${sysroot}" \
    --program-prefix="${COMPILER_TARGET}-" \
	--disable-bootstrap \
    ${GCC_CONF_ARGS}

## Build, build, build!
make -j ${nproc}
make install


if [[ ${COMPILER_TARGET} == *-apple-* ]]; then
    # We need to use this `ld` as if it were `ld64.macos`, so make a symlink:
    ln -s ${COMPILER_TARGET}-ld ${prefix}/bin/ld64.macos

    # Create -fuse-ld=macos wrappers for `clang` and `clang++`
    for tool in clang clang++; do
        target_tool=${prefix}/bin/${tool}
        echo '#!/bin/bash' > ${target_tool}
        echo "/opt/x86_64-linux-musl/bin/${tool} \"\$*\" -fuse-ld=macos" >> ${target_tool}
        chmod +x ${target_tool}
    done
fi

# Create a bunch of symlinks stripping out the target so that
# things like `gcc` "just work", as long as we've got our path set properly
# We don't worry about failure to create these symlinks, as sometimes there are files
# named ridiculous things like ${target}-${target}-foo, which screws this up.
# We also go the reverse direction, as when we're not cross-compiling, it doesn't
# automatically create the properly
#for f in ${prefix}/bin/${COMPILER_TARGET}-*; do
#    fbase=$(basename $f)
#    ln -sv "${fbase}" "${prefix}/bin/${fbase#${COMPILER_TARGET}-}" || true
#done
"""

# The products that we will ensure are always built
products = Product[
    # Normally, we would want to provide these, but since our build process is expecting
    # things like .exe files, it doesn't quite work properly.  Just forgo them for now.
    #ExecutableProduct("\${target}-gcc", :gcc),
    #ExecutableProduct("\${target}-g++", :gxx),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_info = build_tarballs(ARGS, "$(name)-$(triplet(compiler_target))", gcc_version, sources, script, [compiler_target], products, dependencies; skip_audit=true)
build_info = Dict(host_platform => first(values(build_info)))

# Upload the artifacts
upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, gcc_version, build_info; target=compiler_target)
