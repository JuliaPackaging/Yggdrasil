using BinaryBuilder
using Pkg

name = "taskwarrior"
version = v"3.4.2"

sources = [
    GitSource("https://github.com/GothenburgBitFactory/taskwarrior", "48fb891c30fd7c572db3a4cff46e3435c75a1b6c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/taskwarrior/

git submodule update --init

# Remove rustup check in corrosion's FindRust.cmake
pushd src/taskchampion-cpp/corrosion && \
    atomic_patch -p1 ../../../../patches/corrosion-remove-rustup-check.patch && \
    popd

# Build cxxbridge for the build host so Corrosion does not try to execute a
# target binary while generating C++ bridge sources.
cxx_version=$(awk '
    /^\[\[package\]\]$/ { pkg="" }
    $1 == "name" && $2 == "=" { gsub(/"/, "", $3); pkg=$3 }
    pkg == "cxx" && $1 == "version" && $2 == "=" {
        gsub(/"/, "", $3)
        print $3
        exit
    }
' Cargo.lock)
test -n "${cxx_version}"
cargo install cxxbridge-cmd --version "${cxx_version}" --locked --root "${WORKSPACE}/host-tools" --target "${rust_host}"

RUSTFLAGS="-C target-feature=-crt-static" \
cargo install bindgen-cli --locked --root "${WORKSPACE}/host-tools" --target "${rust_host}"
export PATH="${WORKSPACE}/host-tools/bin:${PATH}"
export LIBCLANG_PATH=/opt/x86_64-linux-musl/lib/libclang.so
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=/opt/${target}/${target}/sys-root"

# Needs at least CMake 3.22, BB image has 3.21 currently
apk del cmake

mkdir build
cd build

cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DFETCHCONTENT_SOURCE_DIR_CORROSION=${WORKSPACE}/srcdir/taskwarrior/src/taskchampion-cpp/corrosion \
    -DRust_COMPILER=$(which ${RUSTC}) \
    -DRust_CARGO_TARGET=${CARGO_BUILD_TARGET} \
    ..

make -j${nproc}
make install
"""

# Filter out targets blocked by missing Rust toolchains in BinaryBuilder
platforms = supported_platforms()

platforms = filter(platforms) do p
    if arch(p) == "riscv64"
        return false
    elseif Sys.isfreebsd(p) && arch(p) == "aarch64"
        return false
    elseif arch(p) in ("i686", "armv6l", "armv7l")
        return false
    elseif Sys.iswindows(p)
        return false
    elseif Sys.isapple(p) && arch(p) == "x86_64"
        return false
    else
        return true
    end
end

libuuid_platforms = filter(p -> !(Sys.isapple(p) || Sys.isfreebsd(p)), platforms)
musl_platforms = filter(p -> Sys.islinux(p) && libc(p) == "musl", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("task", :task),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Needs at least CMake 3.22, BB image has 3.21 currently
    HostBuildDependency("CMake_jll"),
    Dependency("Libuuid_jll"; platforms=libuuid_platforms),
    Dependency("LibUnwind_jll"; platforms=musl_platforms),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.10", preferred_gcc_version=v"11")
