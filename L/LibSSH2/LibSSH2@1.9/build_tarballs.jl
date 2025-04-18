using BinaryBuilder
using Pkg
using BinaryBuilderBase: sanitize

name = "LibSSH2"
upstream_version = v"1.9.0"
# Note: we explicitly lie about this because we don't have the new
# versioning APIs worked out in BB yet.
version = v"1.9.1"

# Collection of sources required to build LibSSH2
sources = [
    ArchiveSource("https://github.com/libssh2/libssh2/releases/download/libssh2-$(upstream_version)/libssh2-$(upstream_version).tar.gz",
                  "d5fb8bd563305fd1074dda90bd053fb2d29fc4bce048d182f96eaa466dfadafd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libssh2*/

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

BUILD_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DCRYPTO_BACKEND=mbedTLS
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
    -DENABLE_ZLIB_COMPRESSION=OFF
    "-DCMAKE_INSTALL_PREFIX=${prefix}"
    "-DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}""
)

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
    Dependency("MbedTLS_jll", v"2.24.0"),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_llvm_version=llvm_version)
