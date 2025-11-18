using BinaryBuilder
using Pkg

name = "MGARD"
version = v"1.6.0"

# Collection of sources required to build MGARD
sources = [
    GitSource("https://github.com/CODARcode/MGARD", "024ccc2b8ca4a787cfc6f227a6d14e7fd9cb76cb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd MGARD

# We installed a `protoc` executable both as a build- and a host-build-dependency.
# Delete the non-host-build `protoc` executable so that cmake won't try to run it.
rm ${bindir}/protoc${exeext}
ls -l ${host_bindir}/protoc

# pkg-config is very slow because `abseil_cpp` installed about 200 `*.pc` files.
# Pretend that `protobuf` does not require `abseil_cpp`.
mv /workspace/destdir/lib/pkgconfig/protobuf.pc /workspace/destdir/lib/pkgconfig/protobuf.pc.orig
sed -e 's/Requires/# Requires/' /workspace/destdir/lib/pkgconfig/protobuf.pc.orig >/workspace/destdir/lib/pkgconfig/protobuf.pc

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

# Restore files
mv /workspace/destdir/lib/pkgconfig/protobuf.pc.orig /workspace/destdir/lib/pkgconfig/protobuf.pc
"""

# We enable all platforms
platforms = expand_cxxstring_abis(supported_platforms())

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
