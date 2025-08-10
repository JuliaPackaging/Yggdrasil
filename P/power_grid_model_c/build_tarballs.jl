# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "power_grid_model_c"
version = v"1.12.0"

# Collection of sources required to complete build
sources = [
           ArchiveSource("https://github.com/PowerGridModel/power-grid-model/releases/download/v$(version)/power_grid_model-$(version).tar.gz", 
                      "b38be158af11541759b7b2c01e1baab099f8f22fe453237d7814a8698bb67745")
          ]

# Bash recipe for building across all platforms.
script = raw"""
apk del cmake
cd $WORKSPACE/srcdir/power_grid_model-1.12.0
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_CXX_STANDARD=20 -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
install_license $WORKSPACE/srcdir/power_grid_model-1.12.0/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# no need for i686 builds, may even crash julia REPL.
platforms = filter!(p -> !(arch(p) == "i686"), platforms)

# the riscv64 platform has no-boost implementation, remove
platforms = filter!(p -> !(arch(p) == "riscv64"), platforms)

# Apple build reports "fatal error: 'concepts' file not found"
# it needs a higher version of boost_jll, 
# whhich in turn needs an upgrade of msgpack_jll. maybe later, remove.
platforms = filter(p -> !Sys.isapple(p), platforms)

# cmake reprts "Could NOT find Boost (missing: Boost_INCLUDE_DIR)",
# on aarch64-unknown-freebsd, remove
platforms = filter!(p -> !(os(p) == "freebsd"), platforms)

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
                Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
                Dependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
                Dependency(PackageSpec(name="nlohmann_json_jll", uuid="7c7c7bd4-5f1c-5db3-8b3f-fcf8282f06da"))
                Dependency(PackageSpec(name="msgpack_cxx_jll", uuid="b129c591-c9d9-59ef-8959-ff59aa278493"))
                Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
                HostBuildDependency(PackageSpec(name="CMake_jll", version=v"3.31.6"))
               ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version = v"14.2.0")
