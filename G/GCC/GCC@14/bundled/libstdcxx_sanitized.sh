# Builds a MemorySanitizer libstdc++ for `x86_64-linux-gnu-sanitize+memory`.
# GCC cannot build with MemorySanitizer, so this builds only libstdc++,
# standalone and with clang.

cd ${WORKSPACE}/srcdir
gcc_version="$(echo gcc-* | cut -d- -f2)"
cd ${WORKSPACE}/srcdir/gcc-*/

# Patches that let clang build libstdc++
for p in ${WORKSPACE}/srcdir/bundled/patches/libstdcxx-sanitizers/*.patch; do
    atomic_patch -p1 "${p}"
done

mkdir -p ${WORKSPACE}/srcdir/build
cd ${WORKSPACE}/srcdir/build
# libstdc++'s configure empties an unset CXXFLAGS; a full GCC build passes `-g -O2`
export CXXFLAGS="-g -O2"
# A build triplet distinct from the host stops configure from running msan test programs,
# which can crash at startup under ASLR
${WORKSPACE}/srcdir/gcc-*/libstdc++-v3/configure \
    --prefix="${prefix}" \
    --host="${target}" \
    --build="x86_64-build-linux-gnu" \
    --with-cross-host="${MACHTYPE}" \
    --with-gxx-include-dir="${prefix}/${target}/include/c++/${gcc_version}" \
    --disable-multilib \
    --disable-werror \
    --enable-shared \
    --enable-threads=posix \
    --enable-tls

# Configure cannot run its feature tests when cross-compiling
cat >> config.h <<'END'
#undef _GLIBCXX_USE_C99_FENV_TR1
#undef _GLIBCXX_X86_RDSEED
#undef _GLIBCXX_X86_RDRAND
#undef HAVE_ALIGNED_ALLOC
#define _GLIBCXX_HAS_GTHREADS 1
#define HAVE_CC_TLS 1
#define HAVE_TLS 1
END

make -j${nproc}
make install

# Match the layout of the libstdc++ that is extracted from a GCC build
mkdir -p ${prefix}/${target}/lib64
find ${prefix} -path ${prefix}/${target}/lib64 -prune -o -name 'libstdc++*' \( -type f -o -type l \) -exec mv -t ${prefix}/${target}/lib64 {} +

install_license ${WORKSPACE}/srcdir/gcc-*/COPYING*
