using BinaryBuilder

name = "DecFP"
version = v"2.0.2" # 2.0 Update 2

# Collection of sources required to build DecFP
sources = [
    ArchiveSource("https://www.netlib.org/misc/intel/IntelRDFPMathLib20U2.tar.gz",
                  "93c0c78e0989df88f8540bf38d6743734804cef1e40706fd8fe5c6a03f79e173"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/IntelRDFPMathLib20U2
patch --binary -p1 < $WORKSPACE/srcdir/patches/decfp.patch
cd LIBRARY
if [[ $nbits == 64 ]]; then
     _HOST_ARCH=x86_64
else
     _HOST_ARCH=x86
fi
if [[ $target == *-w64-* ]]; then
    _HOST_OS="Windows_NT"
    objext="obj"
elif [[ $target == *-darwin* ]]; then
    _HOST_OS="Darwin"
    objext="o"
elif [[ $target == *-freebsd* ]]; then
    _HOST_OS="FreeBSD"
    objext="o"
else
    _HOST_OS="Linux"
    objext="o"
fi
CFLAGS_OPT="-fPIC -fsigned-char -D__ENABLE_BINARY80__=0"
if [[ $target == *"-musl"* ]]; then
    CFLAGS_OPT+=" -D__QNX__"
elif [[ $target == *"freebsd"* ]]; then
    CFLAGS_OPT+=" -D__linux"
fi
make CC_NAME=cc CFLAGS_OPT="$CFLAGS_OPT" CFLAGS="$CFLAGS_OPT" _HOST_OS="$_HOST_OS" AR_CMD="ar rv" _HOST_ARCH=$_HOST_ARCH CALL_BY_REF=0 GLOBAL_RND=0 GLOBAL_FLAGS=0 UNCHANGED_BINARY_FLAGS=0
$CC $LDFLAGS -shared -o libbid.$dlext *.$objext
mkdir -p ${libdir}
cp libbid.$dlext ${libdir}
install_license ../eula.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() # build on all supported platforms

# The products that we will ensure are always built
products = [
    LibraryProduct("libbid", :libbid)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
