using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

name = "LibGit2"
version = v"1.8.0"

# Collection of sources required to build libgit2
sources = [
    GitSource("https://github.com/libgit2/libgit2.git", "d74d491481831ddcd23575d376e56d2197e95910")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgit2*

BUILD_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DUSE_THREADS=ON
    -DUSE_BUNDLED_ZLIB=ON
    -DUSE_SSH=ON
    -DBUILD_CLI=OFF
    "-DCMAKE_INSTALL_PREFIX=${prefix}"
    "-DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}""
    # Make sure we don't link to mbedTLS:
    # <https://github.com/JuliaPackaging/Yggdrasil/pull/8377#issuecomment-2027370830>.
    # TODO: this hack can be removed when we'll link to a newer version of libssh2 which
    # doesn't link to mbedTLS.
    -DLIBSSH2_LDFLAGS="-L${libdir};-lssh2"
    -DLIBSSH2_LIBRARIES="ssh2"
)

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

# Special windows flags
if [[ ${target} == *-mingw* ]]; then
    BUILD_FLAGS+=(-DWIN32=ON -DMINGW=ON -DBUILD_TESTS=OFF)
    if [[ ${target} == i686-* ]]; then
        BUILD_FLAGS+=(-DCMAKE_C_FLAGS="-mincoming-stack-boundary=2")
    fi

    # For some reason, CMake fails to find libssh2 using pkg-config.
    BUILD_FLAGS+=(-Dssh2_RESOLVED=${bindir}/libssh2.dll)
elif [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]] || [[ ${target} == *openbsd* ]]; then
    # If we're on Linux or FreeBSD, explicitly ask for OpenSSL
    BUILD_FLAGS+=(-DUSE_HTTPS=OpenSSL -DUSE_SHA1=CollisionDetection -DCMAKE_INSTALL_RPATH="\$ORIGIN")
fi

# Necessary for cmake to find openssl on Windows
if [[ ${target} == x86_64-*-mingw* ]]; then
    export OPENSSL_ROOT_DIR=${prefix}/lib64
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
    LibraryProduct("libgit2", :libgit2),
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibSSH2_jll"; compat="1.11.0"),
    Dependency("OpenSSL_jll"; compat="3.0.8"),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_llvm_version=llvm_version)
