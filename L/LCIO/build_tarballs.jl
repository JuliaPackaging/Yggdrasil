# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build LCIOBuilder
sources = [
    "https://github.com/iLCSoft/LCIO/archive/v02-12-01.tar.gz" =>
    "8a3d2e66c2f2d4489fc2e1c96335472728d913d4090327208a1d93b3b0728737",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir build
cd build
ln -s /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/sys /usr/include
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain ../LCIO-02-12-01/
VERBOSE=ON cmake --build . --config Release --target install
rm /usr/include/sys
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc4)),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc7)),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc8)),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc7,:cxx11)),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc8,:cxx11)),
    MacOS(:x86_64, compiler_abi=CompilerABI(:gcc7)),
    MacOS(:x86_64, compiler_abi=CompilerABI(:gcc8)),
]
# platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "liblcio", :liblcio),
    LibraryProduct(prefix, "libsio", :libsio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	"https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.3/build_Zlib.v1.2.11.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "LCIOBuilder", VersionNumber("v02.12.01-04"), sources, script, platforms, products, dependencies)
