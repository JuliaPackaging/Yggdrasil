using BinaryBuilder

name = "DecFP"
upstream_version = "20U3"
# when updating build_tarballs.jl bump patch to 301, 302...
ygg_version = v"2.0.300"

sources = [
    ArchiveSource("https://www.netlib.org/misc/intel/IntelRDFPMathLib$(upstream_version).tar.gz",
                  "13f6924b2ed71df9b137a7df98706a0dcc3b43c283a0e32f8b6eadca4305136a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
atomic_patch -p1 patches/long_string.patch
atomic_patch -p1 patches/memory.patch
atomic_patch -p1 patches/windows.patch
atomic_patch -p1 patches/align.patch
cd LIBRARY
if [[ ${nbits} == 64 ]]; then
    HOST_ARCH="x86_64"
else
    HOST_ARCH="x86"
fi
CFLAGS_OPT="-O2 -fPIC -fsigned-char"
if [[ ${target} == *-w64-* ]]; then
    HOST_OS="Windows_NT"
    CC="clang"
    CFLAGS_OPT+=" -DBID_SIZE_LONG=4"
    objext="obj"
elif [[ ${target} == *-darwin* ]]; then
    HOST_OS="Darwin"
    # clang causes failed tests on x86_64
    CC="gcc"
    CFLAGS_OPT+=" -DBID_SIZE_LONG=8"
    objext="o"
elif [[ ${target} == *-freebsd* ]]; then
    HOST_OS="FreeBSD"
    CC="clang"
    CFLAGS_OPT+=" -D__QNX__ -D__linux -DBID_SIZE_LONG=8"
    objext="o"
else
    HOST_OS="Linux"
    CC="gcc"
    if [[ ${target} == *-musl* ]]; then
        CFLAGS_OPT+=" -D__QNX__"
    fi
    if [[ ${nbits} == 64 ]]; then
        CFLAGS_OPT+=" -DBID_SIZE_LONG=8"
    else
        CFLAGS_OPT+=" -DBID_SIZE_LONG=4"
    fi
    objext="o"
fi
export CC CFLAGS_OPT
make _HOST_ARCH="${HOST_ARCH}" _HOST_OS="${HOST_OS}" CALL_BY_REF=0 GLOBAL_RND=0 GLOBAL_FLAGS=0 UNCHANGED_BINARY_FLAGS=0 NO_BINARY80=1
mkdir -p "${libdir}"
${CC} -shared -o "${libdir}/libbid.${dlext}" *.${objext}
install_license ../eula.txt
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libbid", :libbid)
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.7")
