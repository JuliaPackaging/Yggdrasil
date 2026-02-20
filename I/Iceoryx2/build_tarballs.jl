using BinaryBuilder, Pkg

name = "Iceoryx2"
version = v"0.8.1"

sources = [
    GitSource("https://github.com/eclipse-iceoryx/iceoryx2", "adf3f519755072e1f62e6a3396cbf4cc7e514e47"),
]

# Bash recipe for building across all platforms
script = raw"""
apk del cmake
cd ${WORKSPACE}/srcdir/iceoryx2/

# Use system linker; avoid rust-lld zlib debug-section issues on x86_64-linux-gnu.
if [[ "${target}" == x86_64-linux-gnu* ]]; then
    export RUSTFLAGS="-C linker=${CC} -C link-arg=-fuse-ld=bfd"
fi

# Use libc-platform feature to avoid bindgen on Linux
if [[ "${target}" == *-linux-* ]]; then
    EXTRA_FLAGS="-DIOX2_FEATURE_LIBC_PLATFORM=ON"
else
    EXTRA_FLAGS=""
fi

cmake -S . -B target/ff/cc/build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_CXX=OFF \
    -DRUST_TARGET_TRIPLET=${rust_target} \
    ${EXTRA_FLAGS}

# Build
cmake --build target/ff/cc/build

# Install
cmake --install target/ff/cc/build --prefix ${prefix}

# Install license files for audit
LICENSE_DIR="${prefix}/share/licenses/Iceoryx2"
mkdir -p "${LICENSE_DIR}"
for license_file in LICENSE-APACHE LICENSE-MIT NOTICE.md; do
    if [[ -f "${license_file}" ]]; then
        cp "${license_file}" "${LICENSE_DIR}/"
    fi
done
"""

platforms = [
    Platform("x86_64",  "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libiceoryx2_ffi_c", :libiceoryx2_ffi_c),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
    Dependency(PackageSpec(; name="CompilerSupportLibraries_jll")),
]

# Build the tarballs
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    compilers=[:c, :rust], julia_compat="1.10", preferred_gcc_version=v"11",
)
