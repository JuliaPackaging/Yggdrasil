# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "power_grid_model_c"
version = v"1.13.145"

# Collection of sources required to complete build
sources = [
           ArchiveSource("https://github.com/PowerGridModel/power-grid-model/releases/download/v$(version)/power_grid_model-$(version).tar.gz", 
                      "6738ddd1b9b289223709b4b842af3d663a72eaa8beb4b2de12ad0be02e89c8cd"),
           ArchiveSource("https://github.com/joseluisq/MacOSX-SDKs/releases/download/15.0/MacOSX15.0.sdk.tar.xz",
                      "9df0293776fdc8a2060281faef929bf2fe1874c1f9368993e7a4ef87b1207f98"),
          ]

# Bash recipe for building across all platforms.
script = raw"""
if [[ "${target}" == *-apple-darwin* ]]; then
    # Install a newer SDK which supports C++20
    # including std::format and concepts... which were added even later than c++20 support
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX15.0.sdk
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    export MACOSX_DEPLOYMENT_TARGET=15.0
    export CXXFLAGS="-fexperimental-library -DBOOST_NO_CXX98_FUNCTION_BASE"
fi
apk del cmake
cd $WORKSPACE/srcdir/power_grid_model-*
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_CXX_STANDARD=20 -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
install_license $WORKSPACE/srcdir/power_grid_model-*/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# no need for i686 builds, may even crash julia REPL.
platforms = filter!(p -> !(arch(p) == "i686"), platforms)

# the riscv64 platform has no-boost implementation, remove
platforms = filter!(p -> !(arch(p) == "riscv64"), platforms)

# x86_64-apple-darwin14 (macOS 10.10) lacks std::aligned_alloc; needs 10.15+
platforms = filter!(p -> !(Sys.isapple(p) && arch(p) == "x86_64"), platforms)

# cmake reprts "Could NOT find Boost (missing: Boost_INCLUDE_DIR)",
# on aarch64-unknown-freebsd, remove
platforms = filter!(p -> !Sys.isfreebsd(p), platforms)

# cmake reports "note: parameter passing for argument of type ‘struct format_args’ changed in GCC 9.1", remove
platforms = filter!(p -> cxxstring_abi(p) != "cxx03" && arch(p) != "armv6l", platforms)
platforms = filter!(p -> cxxstring_abi(p) != "cxx03" && (arch(p) != "armv7l"), platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built.
products = [
            LibraryProduct("libpower_grid_model_c", :libpower_grid_model_c; dont_dlopen=true)
           ]

# Dependencies that must be installed before this package can be built
dependencies = [
                Dependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
                Dependency(PackageSpec(name="nlohmann_json_jll", uuid="7c7c7bd4-5f1c-5db3-8b3f-fcf8282f06da"))
                Dependency(PackageSpec(name="msgpack_cxx_jll", uuid="b129c591-c9d9-59ef-8959-ff59aa278493"))
                Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
                HostBuildDependency(PackageSpec(name="CMake_jll", version=v"3.31.6"))
               ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version = v"14.2.0")
