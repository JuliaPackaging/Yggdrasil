### Instructions for adding a new version
#
# * add the sources, GCC and its dependencies.  For the dependencies you can use
#   the highest between the version used in our preceding build of GCC and the
#   versions listed in the file
#   [`contrib/download_prerequisites`](https://gcc.gnu.org/git/?p=gcc.git;a=blob;f=contrib/download_prerequisites;hb=HEAD)
# * add the relevant entry to the mapping gcc -> binutils, and add the binutils
#   source if necessary.  The version of binutils to use depends on what works
#   during the build.  A good initial value can be found in
#   https://wiki.osdev.org/Cross-Compiler_Successful_Builds
# * create the directory `0_RootFS/GCCBootstrap@X`.  You can copy the
#   `build_tarballs.jl` file from `0_RootFS/GCCBootstrap@X-1` and change the
#   version to build.  In order to reduce patches duplication, we want to use as
#   many symlinks as possible, so link to previously existing patches whenever
#   possible.  This bash command should be useful:
#
#      ORIGDIR=../../../GCCBootstrap@XYZ/bundled/patches; for p in ${ORIGDIR}/{,*/}*.patch; do DESTDIR=$(dirname ${p#"${ORIGDIR}/"}); mkdir -p "${DESTDIR}"; if [[ -L "${p}" ]]; then cp -a "${p}" "${DESTDIR}"; else ln -s $(realpath --relative-to="${DESTDIR}" "${p}") "${DESTDIR}"; fi; done
#
# * adapt the recipe as necessary, but try to make changes in a backward
#   compatible way.  If you introduce steps that are necessary only with
#   specific versions of GCC, guard them with appropriate conditionals.  We may
#   need to use the same recipe to rebuild older versions of GCC at a later
#   point and being able to rerun it as-is is extremely important
# * you can build only one platform at the time.  To deploy the compiler shards
#   and automatically update your BinaryBuilderBase's `Artifacts.toml`, use the
#   `--deploy` flag to the `build_tarballs.jl` script.  You can either build &
#   deploy the compilers one by one or run something like
#
#      for p in i686-linux-gnu x86_64-linux-gnu aarch64-linux-gnu armv7l-linux-gnueabihf powerpc64le-linux-gnu riscv64-linux-gnu i686-linux-musl x86_64-linux-musl aarch64-linux-musl armv7l-linux-musleabihf x86_64-apple-darwin14 x86_64-unknown-freebsd13.2 aarch64-unknown-freebsd13.2 i686-w64-mingw32 x86_64-w64-mingw32; do julia build_tarballs.jl --debug --verbose --deploy "${p}"; done

include("./common.jl")
include("./gcc_sources.jl")

using BinaryBuilder
using BinaryBuilder: BinaryBuilderBase
@eval BinaryBuilder.BinaryBuilderBase empty!(bootstrap_list)
@eval BinaryBuilder.BinaryBuilderBase push!(bootstrap_list, :rootfs, :platform_support)


function gcc_script(gcc_version::VersionNumber, compiler_target::Platform)
    script = """
    GCC_VERSION_MAJOR=$(gcc_version.major)
    GCC_VERSION_MINOR=$(gcc_version.minor)
    GCC_VERSION_PATCH=$(gcc_version.patch)
    """

    script *= raw"""
    cd ${WORKSPACE}/srcdir
    COMPILER_TARGET=${target}
    HOST_TARGET=${MACHTYPE}

    # Increase max file descriptors
    fd_lim=$(ulimit -n -H)
    ulimit -n $fd_lim

    # Update list of packages before installing new packages
    apk update
    # Install `gcc` from `apk`, which we'll use to bootstrap ourselves a BETTER `gcc`
    apk add build-base gettext-dev gcc-objc clang texinfo

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

    # Some things need /lib64, others just need /lib.  Be consistent with where
    # our compiler wrappers expect the libraries to be:
    # <https://github.com/JuliaPackaging/BinaryBuilderBase.jl/blob/4d0883a222bcb60871f8e24e56ef6e322502ec80/src/Runner.jl#L553-L559>.
    case ${nbits} in
        64)
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
        # We choose the armv6 arch by default for compatibility
        GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-float=hard --with-arch=armv6 --with-fpu=vfp"
    elif [[ "${COMPILER_TARGET}" == x86_64* ]]; then
        GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-arch=x86-64"
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
        # Always disable TLS: https://github.com/JuliaLang/julia/pull/45582#issuecomment-1295697412
        GCC_CONF_ARGS="${GCC_CONF_ARGS} --disable-tls"

    elif [[ "${COMPILER_TARGET}" == *-darwin* ]]; then
        # Use llvm archive tools to dodge binutils bugs
        export LD_FOR_TARGET=${prefix}/bin/${COMPILER_TARGET}-ld
        export AS_FOR_TARGET=${prefix}/bin/llvm-as
        export AR_FOR_TARGET=${prefix}/bin/llvm-ar
        export NM_FOR_TARGET=${prefix}/bin/llvm-nm
        export RANLIB_FOR_TARGET=${prefix}/bin/llvm-ranlib
        export DSYMUTIL_FOR_TARGET=${prefix}/bin/dsymutil

        # GCC build needs a little extra help finding our binutils
        GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-ld=${prefix}/bin/${COMPILER_TARGET}-ld"
        GCC_CONF_ARGS="${GCC_CONF_ARGS} --with-as=${prefix}/bin/${COMPILER_TARGET}-as"

        # GCC doesn't turn LTO on by default for some reason.
        GCC_CONF_ARGS="${GCC_CONF_ARGS} --enable-lto --enable-plugin"

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
    if [[ ${COMPILER_TARGET} != *-darwin* ]]; then
        sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
    fi

    # Apply all gcc patches
    for p in ${WORKSPACE}/srcdir/patches/gcc*.patch; do
        atomic_patch -p1 "${p}" || true
    done
    # Apply other gcc patches WITHOUT IGNORING FAILURES!!
    if [[ -d "${WORKSPACE}/srcdir/patches/gcc" ]]; then
        for p in ${WORKSPACE}/srcdir/patches/gcc/*.patch; do
            atomic_patch -p1 "${p}"
        done
    fi

    # Disable any non-POSIX usage of TLS for musl
    if [[ "${COMPILER_TARGET}" == *musl* ]] && [[ -f "${WORKSPACE}/srcdir/patches/musl_disable_tls.patch" ]]; then
        patch -p1 $WORKSPACE/srcdir/gcc-*/libgomp/configure.tgt ${WORKSPACE}/srcdir/patches/musl_disable_tls.patch
    fi

    # If we're on MacOS, we need to install cctools first, separately.
    if [[ ${COMPILER_TARGET} == *-darwin* ]]; then
        cd ${WORKSPACE}/srcdir/apple-libtapi

        # Apply libtapi patches, if any
        if [[ -d "${WORKSPACE}/srcdir/patches/libtapi" ]]; then
            for p in ${WORKSPACE}/srcdir/patches/libtapi/*.patch; do
                atomic_patch -p1 "${p}"
            done
        fi

        # Install libtapi
        mkdir -p ${WORKSPACE}/srcdir/apple-libtapi/build
        cd ${WORKSPACE}/srcdir/apple-libtapi/build
        export TAPIDIR=${WORKSPACE}/srcdir/apple-libtapi

        TAPI_CMAKE_FLAGS=()
        if [[ "${GCC_VERSION_MAJOR}" -ge 14 ]]; then
            TAPI_CMAKE_FLAGS+=(
                -DLLVM_ENABLE_PROJECTS="tapi;clang"
                -DLLVM_TARGETS_TO_BUILD:STRING="host"
            )
        fi

        cmake ../src/llvm \
            -DCMAKE_C_COMPILER_LAUNCHER=ccache \
            -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
            -DCMAKE_CXX_FLAGS="-I${TAPIDIR}/src/llvm/projects/clang/include -I${TAPIDIR}/build/projects/clang/include" \
            -DLLVM_INCLUDE_TESTS=OFF \
            -DCMAKE_BUILD_TYPE=RELEASE \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            "${TAPI_CMAKE_FLAGS[@]}"
        make -j${nproc} VERBOSE=1 clangBasic
        make -j${nproc} VERBOSE=1 libtapi
        make -j${nproc} VERBOSE=1 install

        # Install cctools
        cd ${WORKSPACE}/srcdir/cctools-port/cctools
        ./autogen.sh
        mkdir -p ${WORKSPACE}/srcdir/cctools_build
        cd ${WORKSPACE}/srcdir/cctools_build

        # TODO: Update RootFS to v3.17 or later, and preinstall libdispatch (and libdispatch-dev here only when building for macOS).
        if [[ "${GCC_VERSION_MAJOR}" -ge 14 ]]; then
            apk add libdispatch libdispatch-dev --repository=http://dl-cdn.alpinelinux.org/alpine/v3.17/community
        fi

        ${WORKSPACE}/srcdir/cctools-port/cctools/configure \
            --prefix=${prefix} \
            --target=${COMPILER_TARGET} \
            --host=${MACHTYPE} \
            CC=/usr/bin/clang \
            CXX=/usr/bin/clang++ \
            LDFLAGS=-L/usr/lib \
            --with-libtapi=${prefix}
        make -j${nproc}
        make install

    # Otherwise, we need to install binutils first
    else
        # We also need to build binutils
        cd ${WORKSPACE}/srcdir/binutils-*

        # Patch to make `dlltool` use deterministic mode when building static libraries
        atomic_patch -p1 $WORKSPACE/srcdir/patches/binutils_deterministic_dlltool.patch

        # Patch for building binutils 2.30+ against FreeBSD
        atomic_patch -p1 $WORKSPACE/srcdir/patches/binutils_freebsd_symbol_versioning.patch || true

        #gprofng doesn't build on musl anymore ;(
        ./configure --prefix=${prefix} \
            --target=${COMPILER_TARGET} \
            --host=${MACHTYPE} \
            --with-sysroot="${sysroot}" \
            --enable-multilib \
            --program-prefix="${COMPILER_TARGET}-" \
            --disable-werror \
            --enable-deterministic-archives \
            --disable-gprofng
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

    CFLAGS="$CFLAGS -D_GNU_SOURCE"
    CXXFLAGS="$CXXFLAGS -D_GNU_SOURCE"
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

        # patch glibc's stupid gcc/make version checks (we don't require these,
        # as if it doesn't apply cleanly, it's probably fine).  We also keep them
        # separate, as some glibc versions require one or not the other.  BTW,
        # the three versions of glibc we use require three different patches :(
        atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_gcc_version.patch || true
        atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc217_gcc_version.patch || true
        atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc219_gcc_version.patch || true
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

        # Patch for building glibc 2.12.2 on x86_64-linux-gnu with GCC 12+.
        # Adapted from new definition of `_dl_setup_stack_chk_guard` from
        # https://github.com/bminor/glibc/commit/4a103975c4c4929455d60224101013888640cd2f.
        atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc-remove-__ASSUME_AT_RANDOM-in-_dl_setup_stack_chk_guard.patch || true

        # Patches for building glibc 2.17 on ppc64le
        for p in ${WORKSPACE}/srcdir/patches/glibc-ppc64le-*.patch; do
            atomic_patch -p1 ${p} || true
        done

        # Patch bad `movq` argument in glibc 2.17, adapted from:
        # https://github.com/bminor/glibc/commit/b1ec623ed50bb8c7b9b6333fa350c3866dbde87f
        # X-ref: https://github.com/crosstool-ng/crosstool-ng/issues/1825#issuecomment-1437918391
        atomic_patch -p1 $WORKSPACE/srcdir/patches/glibc_movq_fix.patch || true

        # Various configure overrides
        GLIBC_CONFIGURE_OVERRIDES=( libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes )

        # We have problems with libssp on ppc64le, x86_64 and i686
        if [[ ${COMPILER_TARGET} == powerpc64le-* ]] || [[ ${COMPILER_TARGET} == x86_64-* ]] || [[ ${COMPILER_TARGET} == i686-* ]]; then
            GLIBC_CONFIGURE_OVERRIDES+=( libc_cv_ssp=no libc_cv_ssp_strong=no )
        fi

        # Explicitly disable C++.
        # If we don't do this, glibc will pick up the host C++
        # compiler (/usr/bin/g++) to build some C++ files. With this
        # setting, glibc will build C versions of these files instead.
        GLIBC_CONFIGURE_OVERRIDES+=( CXX=false )

        # These flags are necessary for GCC 14. GCC 14 defaults to a
        # modern version of C, too modern for the old glibc libraries we are
        # trying to build. Various configure tests would fail otherwise. (Why
        # declare variables or functions if they default to int anyway?)
        GLIBC_CFLAGS="${CFLAGS} -g -O2"
        if [[ "${GCC_VERSION_MAJOR}" -ge 14 ]]; then
            GLIBC_CFLAGS="${GLIBC_CFLAGS} -Wno-implicit-int -Wno-implicit-function-declaration -Wno-builtin-declaration-mismatch -Wno-array-parameter -Wno-int-conversion"
        fi

        # Configure glibc
        mkdir ${WORKSPACE}/srcdir/glibc_build
        cd ${WORKSPACE}/srcdir/glibc_build
        ${WORKSPACE}/srcdir/glibc-*/configure \
            --prefix=/usr \
            --host=${COMPILER_TARGET} \
            --build=${HOST_TARGET} \
            --with-headers="${sysroot}/usr/include" \
            --disable-multilib \
            --disable-werror \
            CFLAGS="${GLIBC_CFLAGS}" \
            ${GLIBC_CONFIGURE_OVERRIDES[@]}


        # Install headers
        mkdir -p ${prefix}/${COMPILER_TARGET}/include/gnu
        touch ${prefix}/${COMPILER_TARGET}/include/gnu/stubs.h
        mkdir -p ${sysroot}/usr/include/bits
        touch ${sysroot}/usr/include/bits/stdio_lim.h
        make install_root=${sysroot} install-bootstrap-headers=yes install-headers

        # Install CSU
        make csu/subdir_lib -j${nproc}
        mkdir -p ${sysroot}/usr/${LIB64}
        install -v csu/crt1.o csu/crti.o csu/crtn.o ${sysroot}/usr/${LIB64}
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
        install -v lib/crt1.o lib/crti.o lib/crtn.o ${sysroot}/usr/lib
        ${COMPILER_TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o ${sysroot}/usr/lib/libc.so

    elif [[ ${COMPILER_TARGET} == *-mingw* ]]; then
        # Install headers
        mkdir -p $WORKSPACE/srcdir/mingw_headers
        cd $WORKSPACE/srcdir/mingw_headers
        ${WORKSPACE}/srcdir/mingw-*/mingw-w64-headers/configure \
        --prefix=/ \
        --enable-sdk=no \
        --build=${HOST_TARGET} \
        --host=${COMPILER_TARGET}
        make install DESTDIR=${sysroot}

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

        # Apply MinGW patches, if any
        if [[ -d "${WORKSPACE}/srcdir/patches/mingw" ]]; then
            for p in ${WORKSPACE}/srcdir/patches/mingw/*.patch; do
                atomic_patch -p1 -d ${WORKSPACE}/srcdir/mingw-* "${p}"
            done
        fi

        ${WORKSPACE}/srcdir/mingw-*/mingw-w64-crt/configure \
            --prefix=/ \
            --host=${COMPILER_TARGET} \
            --with-sysroot=${sysroot} \
            ${MINGW_CONF_ARGS}
        # Build serially, it sounds like there are some race conditions in the makefile
        make
        make install DESTDIR=${sysroot}

    elif [[ ${COMPILER_TARGET} == *-darwin* ]]; then
        # Install Darwin libc
        cd ${WORKSPACE}/srcdir/MacOSX*.sdk
        mkdir -p "${sysroot}"
        rsync -a usr "${sysroot}/"
        rsync -a SDKSettings.* "${sysroot}/"

        # Clean out libssl and libcrypto, as we never want to link against those old versions included with MacOS
        rm -rfv ${sysroot}/usr/lib/libssl.*
        rm -rfv ${sysroot}/usr/lib/libcrypto.*

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
    make all-target-libgcc -j${nproc}
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
        # `libc.so` has soname `libc.musl-$(musl_arch).so.1`, we need to have
        # that file as well.
        ln -fsv libc.so ${sysroot}/usr/lib/libc.musl-$(musl_arch).so.1

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
    make -j${nproc}
    make install

    # Remove misleading libtool archives
    rm -f ${prefix}/${COMPILER_TARGET}/lib*/*.la

    # Remove heavy doc directories
    rm -rf ${sysroot}/usr/share/man

    # Remove leftover dummy `libc.so` file:
    # <https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/403#issuecomment-2585717031>.
    if [[ "${target}" == riscv64-linux-gnu ]]; then
        rm -v ${sysroot}/usr/${LIB64}/libc.so
    fi
    """

    return script
end

# The products that we will ensure are always built
function gcc_products(;kwargs...)
    products = Product[
        # Normally, we would want to provide these, but since we are claiming an incorrect
        # platform (e.g. we claim this is for `compiler_target` but it's really for `host_platform`,
        # which we do because we need the appropriate `platofrm_support`) it doesn't find them.
        # We just build with no products for now.
        #ExecutableProduct("\${target}-gcc", :gcc),
        #ExecutableProduct("\${target}-g++", :gxx),
    ]
end

function build_and_upload_gcc(version::VersionNumber, ARGS=ARGS)
    name = "GCCBootstrap"
    compiler_target = try
        parse(Platform, ARGS[end])
    catch
        error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
    end
    deleteat!(ARGS, length(ARGS))

    sources = gcc_sources(version, compiler_target)
    script = gcc_script(version, compiler_target)
    products = gcc_products()

    # Build the tarballs, and possibly a `build.jl` as well.
    ndARGS, deploy_target = find_deploy_arg(ARGS)
    build_info = build_tarballs(ndARGS, name, version, sources, script, [compiler_target], products, Dependency[]; skip_audit=true, julia_compat="1.6")
    build_info = Dict(host_platform => first(values(build_info)))

    # Upload the artifacts (if requested)
    if deploy_target !== nothing
        upload_and_insert_shards(deploy_target, name, version, build_info; target=compiler_target)
    end
    return build_info
end
