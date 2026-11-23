using BinaryBuilder2

name = "Mingw"
version = v"11.0.1"

# mingw-w64 headers, CRT and winpthreads; this is the Windows libc sysroot that
# BinaryBuilder2's GCC toolchains are built against.
sources = [
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v$(version).tar.bz2",
                  "3f66bce069ee8bed7439a1a13da7cb91a5e67ea6170f21317ac7f5794625ee10"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mingw-*/

# Install licenses
install_license ${WORKSPACE}/srcdir/mingw-*/COPYING
install_license ${WORKSPACE}/srcdir/mingw-*/COPYING.*/*.txt

# Install headers
mkdir -p ${WORKSPACE}/srcdir/mingw_headers
cd ${WORKSPACE}/srcdir/mingw_headers
${WORKSPACE}/srcdir/mingw-*/mingw-w64-headers/configure \
    --prefix=${prefix}/usr \
    --enable-sdk=no \
    --with-default-msvcrt=msvcrt \
    --build=${MACHTYPE} \
    --host=${target}
make install

# Build CRT
mkdir -p ${WORKSPACE}/srcdir/mingw_crt_build
cd ${WORKSPACE}/srcdir/mingw_crt_build
MINGW_CONF_ARGS=()

# Only build the CRT for the bitness we're targeting
if [[ "${nbits}" == 32 ]]; then
    MINGW_CONF_ARGS+=( --disable-lib64 )
else
    MINGW_CONF_ARGS+=( --disable-lib32 )
fi

${WORKSPACE}/srcdir/mingw-*/mingw-w64-crt/configure \
    --prefix=${prefix}/usr \
    --with-default-msvcrt=msvcrt \
    --build=${MACHTYPE} \
    --host=${target} \
    "${MINGW_CONF_ARGS[@]}"
make -j${nproc}
make install

# Build winpthreads against the CRT we just built, not the compiler's own
mkdir -p ${WORKSPACE}/srcdir/mingw_winpthreads_build
cd ${WORKSPACE}/srcdir/mingw_winpthreads_build
CPPFLAGS="-isystem ${prefix}/usr/include" \
LDFLAGS="-B${prefix}/usr/lib -L${prefix}/usr/lib" \
${WORKSPACE}/srcdir/mingw-*/mingw-w64-libraries/winpthreads/configure \
    --prefix=${prefix}/usr \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-static \
    --enable-shared
make -j${nproc}
make install

# Flatten `usr/` into the prefix
mv ${prefix}/usr/* ${prefix}/
rmdir ${prefix}/usr
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    FileProduct(["lib/libmsvcrt.a"], :libmsvcrt_a),
    # This is the sysroot copy of winpthreads, and Julia on Windows already loads its own
    # `libwinpthread-1.dll`.  Mark it `dont_dlopen` so that JLL wrappers don't load a second
    # copy eagerly on Julia versions without `LazyLibrary` support.
    LibraryProduct(["libwinpthread"], :libwinpthread; dont_dlopen=true, static=:auto),
]

# Use the bootstrap toolchain, since this is part of building the toolchain itself
host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()]
target_toolchains = [CToolchain(;vendor=:bootstrap)]

# Build the tarballs
build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    host_toolchains,
    target_toolchains,
)
