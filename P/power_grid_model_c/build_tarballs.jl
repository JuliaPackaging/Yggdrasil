# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "power_grid_model_c"
version = v"1.12.0"

# Collection of sources required to complete build
sources = [
           ArchiveSource("https://github.com/PowerGridModel/power-grid-model/releases/download/v$(version)/power_grid_model-$(version).tar.gz", "b38be158af11541759b7b2c01e1baab099f8f22fe453237d7814a8698bb67745"),
           DirectorySource("./bundled")
          ]

# Bash recipe for building across all platforms.
script = raw"""
apk del cmake
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/cmake-patch.patch; do
    atomic_patch -p1 ${f}
done
cd power_grid_model-1.12.0/power_grid_model_c
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_CXX_STANDARD=20 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
install_license $WORKSPACE/srcdir/power_grid_model-1.12.0/LICENSE
"""

platforms = [
             Platform("x86_64", "linux"; libc = "glibc", cpu_target="x86_64_v2", cxxstring_abi=:cxx11),
             Platform("x86_64", "linux"; libc = "glibc", cpu_target="x86_64_v3", cxxstring_abi=:cxx11),
             Platform("aarch64", "linux"; libc = "glibc", cxxstring_abi=:cxx11),
             Platform("x86_64", "linux"; libc = "musl", cxxstring_abi=:cxx11),
             Platform("aarch64", "linux"; libc = "musl", cxxstring_abi=:cxx11),
             Platform("x86_64", "windows"; cpu_target="x86_64_v2", cxxstring_abi=:cxx11, march="avx2"),
             Platform("x86_64", "windows"; cpu_target="x86_64_v3", cxxstring_abi=:cxx11, march="avx2"),
             Platform("x86_64", "linux"; libc="musl", cxxstring_abi=:cxx11),
             Platform("x86_64", "linux"; libc="glibc", cpu_target="znver1", cxxstring_abi=:cxx11, march="avx2"),
             Platform("x86_64", "linux"; libc="glibc", cpu_target="znver2", cxxstring_abi=:cxx11, march="avx2"),
             Platform("x86_64", "linux"; libc="glibc", cpu_target="znver3", cxxstring_abi=:cxx11, march="avx2")
            ]


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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.10", preferred_gcc_version = v"14.2.0")
