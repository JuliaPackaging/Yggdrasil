using BinaryBuilder
using Pkg

name = "MGARD"
version = v"1.5.2"

# Collection of sources required to build MGARD
sources = [
    # GitSource("https://github.com/CODARcode/MGARD", "208b0c42af6ba552387aec321664d5cbb757b2e2"),
    # This is PR 233 for MGARD
    # <https://github.com/CODARcode/MGARD/pull/233>, later than 1.5.2.
    # It includes corrections to support musl.
    GitSource("https://github.com/JieyangChen7/MGARD", "70281b1f3a150ba07f5054c100adf1c2f324f6fd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd MGARD
# We installed a `protoc` executable both as a build- and a host-build-dependency.
# Delete the non-host-build `protoc` executable so that cmake won't try to run it.
rm ${bindir}/protoc${exeext}
ls -l ${host_bindir}/protoc
cmake -B build \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_PROGRAM_PATH=${host_bindir} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DMGARD_ENABLE_OPENMP=ON \
    -DMGARD_ENABLE_SERIAL=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# We enable all platforms
platforms = expand_cxxstring_abis(supported_platforms())

# All BSD (FreeBSD and Apple) builds fail in the cmake stage:
# Finding `protobuf` via pkg-config takes a very long time and times
# out on CI after 4 hours. This might be a bug in pkg-config, its
# executable is running for a very long time.
filter!(!Sys.isbsd, platforms)

# Windows build fail because `CLOCK_REALTIME` is not declared.
# See `N/Notcurses/bundled/headers/pthread_time.h` for a possible fix.
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmgard", :libmgard),
]

# Dependencies that must be installed before this package can be built
# TODO: Support OpenMP
# TODO: Support CUDA
dependencies = [
    HostBuildDependency("protoc_jll"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("protoc_jll"),
]

# We need at least GCC 8 for C++17
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
