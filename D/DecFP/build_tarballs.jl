using BinaryBuilder

name = "DecFP"
upstream_version = "20U4"
# when updating build_tarballs.jl bump patch to 401, 402...
ygg_version = v"2.0.400"

sources = [
    ArchiveSource("https://www.netlib.org/misc/intel/IntelRDFPMathLib$(upstream_version).tar.gz",
                  "1df86132e7a31fd74d784fee1c679b21a088f73a8ec979cfaf784c200392e125"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
atomic_patch -p1 patches/windows.patch
atomic_patch -p1 patches/align.patch
cd LIBRARY
if [[ ${nbits} == 64 ]]; then
    HOST_ARCH="x86_64"
else
    HOST_ARCH="x86"
fi
# __QNX__ makes bid_functions.h take fexcept_t from <fenv.h> instead of
# typedef'ing it, which conflicts with the system definition on non-x86
# glibc and on mingw.
CFLAGS_OPT="-O2 -fPIC -fsigned-char -D__QNX__"
if [[ ${target} == *-w64-* ]]; then
    HOST_OS="Windows_NT"
    CC="clang"
    CFLAGS_OPT+=" -DBID_SIZE_LONG=4"
    objext="obj"
elif [[ ${target} == *-darwin* ]]; then
    HOST_OS="Darwin"
    # Use the default compiler (clang): BinaryBuilder's gcc links libgcc_s with an
    # absolute /workspace path, so the dylib fails to load on user machines
    # (https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1339,
    # https://github.com/JuliaMath/DecFP.jl/issues/195).
    CFLAGS_OPT+=" -DBID_SIZE_LONG=8"
    objext="o"
elif [[ ${target} == *-freebsd* ]]; then
    HOST_OS="FreeBSD"
    CC="clang"
    CFLAGS_OPT+=" -D__linux -DBID_SIZE_LONG=8"
    objext="o"
else
    HOST_OS="Linux"
    CC="gcc"
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
${CC} -shared -o "${libdir}/libbid.${dlext}" *.${objext} -lm
install_license ../eula.txt
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libbid", :libbid)
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.7")
