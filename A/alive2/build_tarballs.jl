# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "alive2"
version = v"0.1.0"

# Collection of sources required to complete build
sources = Any[
    # An alive version from around Sep 2022 to hopefully be compatible with our LLVM version
    GitSource("https://github.com/AliveToolkit/alive2.git", "189436ffe02f44b710111ee5de06ca6b91aaff74"),
    # DirectorySource("./bundled") - Implicitly added by the LLVM configure_build
    # Alive2 requires C++20, which needs a newer SDK
    ArchiveSource("https://github.com/realjf/MacOSX-SDKs/releases/download/v0.0.1/MacOSX12.3.sdk.tar.xz",
                  "a511c1cf1ebfe6fe3b8ec005374b9c05e89ac28b3d4eb468873f59800c02b030"),
]

include("../../L/LLVM/common.jl")

_, _, llvm_sources, llvm_script, platforms, _, llvm_dependencies =
    configure_build(ARGS, v"15.0.7"; eh_rtti=true, update_sdk=false)

filter!(llvm_sources) do source
    isa(source, ArchiveSource) || return true
    contains(source.url, "sdk") && return false
    return true
end

append!(sources, llvm_sources)

sdk_update_script = raw"""
if [[ "${target}" == *-apple-darwin* ]]; then
    # Install a newer SDK which supports C++20
    pushd $WORKSPACE/srcdir/MacOSX12.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/*
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    export MACOSX_DEPLOYMENT_TARGET=12.3
fi
"""

# Bash recipe for building across all platforms
script = sdk_update_script * llvm_script * raw"""
# Build alive2
apk add re2c
cd $WORKSPACE/srcdir/alive2
rm -rf /opt/x86_64-linux-musl/lib/cmake/llvm
rm -rf /opt/x86_64-apple-darwin14/lib/cmake/llvm
rm -rf /opt/aarch64-apple-darwin20/lib/cmake/llvm
for f in ${WORKSPACE}/srcdir/alive_patches/*.patch; do
    atomic_patch -p1 ${f}
done
install_license LICENSE
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DBUILD_TV=1 -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    ExecutableProduct("alive", :alive)
]

# Dependencies that must be installed before this package can be built
dependencies = Any[
    Dependency(PackageSpec(name="z3_jll", uuid="1bc4e1ec-7839-5212-8f2f-0d16b7bd09bc"))
]
append!(dependencies, llvm_dependencies)

filter!(platforms) do p
    # FreeBSD has the same libc++ problem as macos
    Sys.isfreebsd(p) && return false
    # Windows not supported because the LLVM.dll ends up
    # with too many symbols in RTTI mode.
    # See https://reviews.llvm.org/D109192.
    Sys.iswindows(p) && return false
    return true
end

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"11.1.0")
