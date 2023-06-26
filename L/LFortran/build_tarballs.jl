# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LFortran"
version = v"0.19.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://lfortran.github.io/tarballs/release/lfortran-$(version).tar.gz",
                  "d496f61d7133b624deb3562677c0cbf98e747262babd4ac010dbd3ab4303d805"),
    # Required for `std::filesystem` support on macOS x86_64
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lfortran-*

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.15
    # install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_C_FLAGS_RELEASE="-std=gnu99 -O3 -DNDEBUG"
    -DCMAKE_CXX_FLAGS_RELEASE="-Wall -Wextra -O3 -funroll-loops -pthread -D__STDC_FORMAT_MACROS -DNDEBUG"
    -DWITH_LLVM=YES
)

if [[ "${target}" == aarch64* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_WITH_TARGET_AARCH64=YES)
fi

# Stage 1: compiler
cmake . "${CMAKE_FLAGS[@]}" -DWITH_RUNTIME_LIBRARY=NO
make -j${nproc} install

# Stage 2: runtime library
cmake . "${CMAKE_FLAGS[@]}" -DWITH_RUNTIME_LIBRARY=YES -DCMAKE_Fortran_COMPILER=${bindir}/lfortran${exeext}
make -j${nproc} install

install_license LICENSE
install -Dvm 755 "src/bin/cpptranslate${exeext}" "${bindir}/cpptranslate${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = map(supported_platforms(; exclude=(p -> arch(p) != "x86_64"))) do p
    if !Sys.isbsd(p)  # no dependence on libstdc++
        p["cxxstring_abi"] = "cxx11"
    end
    return p
end

# The products that we will ensure are always built
products = [
    LibraryProduct("liblfortran_runtime", :liblfortran_runtime, "share/lfortran/lib"),
    ExecutableProduct("lfortran", :lfortran),
    ExecutableProduct("cpptranslate", :cpptranslate)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_jll", version=v"11.0.1",
                                uuid="86de99a1-58d6-5da7-8064-bd56ce2e322c")),
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9", preferred_llvm_version=v"11")
