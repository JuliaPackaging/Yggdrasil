# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TVM"
version = v"0.10.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dlcdn.apache.org/tvm/tvm-v$(version)/apache-tvm-src-v$(version).tar.gz", "2da001bf847636b32fc7a34f864abf01a46c69aaef0ff37cfbfbcc2eb5b0fce4"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
        "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/apache-tvm-src*/
install_license LICENSE 
mkdir build && cd build

# upgrade MacOS SDK to 10.15
if [[ "$target" == *darwin* ]]; then
    # Work around "'value' is unavailable"
    export MACOSX_DEPLOYMENT_TARGET=10.15
    # ...and install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd    
fi

# setup LLVM_LIBS manually
if [[ "$target" == *mingw* ]]; then
    export LLVM_LIBS="$(ls -1 ${bindir}/libLLVM*.a | paste -sd ";" -);-lrt;-ldl;-lm;-lz;-lxml2"
else
    export LLVM_LIBS="$(ls -1 ${libdir}/libLLVM*.a | paste -sd ";" -);-lrt;-ldl;-lm;-lz;-lxml2"
fi

cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLLD_BIN=${WORKSPACE}/destdir/tools/lld -DUSE_LLVM=ON -DLLVM_LIBS="${LLVM_LIBS}" -DLLVM_DEFINITIONS="-D_GNU_SOURCE;-D__STDC_CONSTANT_MACROS;-D__STDC_FORMAT_MACROS;-D__STDC_LIMIT_MACROS" -DLLVM_INCLUDE_DIRS=${includedir} -DTVM_LLVM_VERSION=#LLVM_VER#0 -G Ninja

ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),

    # dll import woes
    # Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtvm", :libtvm),
    LibraryProduct("libtvm_runtime", :libtvm_runtime),
]

# Dependencies that must be installed before this package can be built
llvm_version = v"14.0.6"
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="XML2_jll")),
    BuildDependency(PackageSpec(name="LLD_jll", version=llvm_version)),
    BuildDependency(PackageSpec(name="LLVM_jll", version=llvm_version)),
    BuildDependency(PackageSpec(name="MLIR_jll", version=llvm_version)),
]

# Build the tarballs, and possibly a `build.jl` as well.
script = replace(script, "#LLVM_VER#" => string(llvm_version.major))
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
