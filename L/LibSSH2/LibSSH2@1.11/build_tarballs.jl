using BinaryBuilder
using Pkg
using BinaryBuilderBase: sanitize

name = "LibSSH2"
# This is a lie, we actually build 1.11.1, but we needed to bump the patch version to change our compat below
version = v"1.11.3"

# Collection of sources required to build LibSSH2
sources = [
    ArchiveSource("https://github.com/libssh2/libssh2/releases/download/libssh2-1.11.1/libssh2-1.11.1.tar.gz",
                  "d9ec76cbe34db98eec3539fe2c899d26b0c837cb3eb466a56b0f109cabf658f7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libssh2*

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

BUILD_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_STATIC_LIBS=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
    -DENABLE_ZLIB_COMPRESSION=OFF
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
)

# Use native backend on Windows, OpenSSL on others
if [[ ${target} == *-mingw* ]]; then
    BUILD_FLAGS+=(-DCRYPTO_BACKEND=WinCNG)
else
    BUILD_FLAGS+=(-DCRYPTO_BACKEND=OpenSSL)
fi

mkdir build && cd build

cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libssh2", :libssh2),
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.15", platforms=filter(!Sys.iswindows, platforms)),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_llvm_version=llvm_version)

# Build trigger: 1
