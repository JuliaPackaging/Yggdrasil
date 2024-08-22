# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROOT"
version = v"6.32.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://root.cern/download/root_v6.32.02.source.tar.gz", "3d0f76bf05857e1807ccfb2c9e014f525bcb625f94a2370b455f4b164961602d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE
install_license srcdir/root-*/LICENSE

# Release type and C++ standard
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DCMAKE_CXX_STANDARD=17)

# ROOT options to enable/disable
CMAKE_FLAGS+=(-Dgnuinstall=OFF)
CMAKE_FLAGS+=(-Drpath=ON)
CMAKE_FLAGS+=(-Dshared=ON)
CMAKE_FLAGS+=(-Dsoversion=OFF)
CMAKE_FLAGS+=(-Dfail-on-missing=ON)
CMAKE_FLAFS+=(-Dbuiltin_afterimage=ON)
CMAKE_FLAGS+=(-Druntime_cxxmodules=OFF)

# LLVM tries to run a bunch of configure tests. Tell it what the output would have been.
CMAKE_FLAGS+=(-Dfound_urandom_EXITCODE=0)
CMAKE_FLAGS+=(-Dfound_urandom_EXITCODE__TRYRUN_OUTPUT='')

export SYSTEM_INCLUDE_PATH= /opt/$MACHTYPE/$MACHTYPE/sys-root/usr/include:/opt/$MACHTYPE/$MACHTYPE/sys-root/usr/local/include
export CPLUS_INCLUDE_PATH=$SYSTEM_INCLUDE_PATH  # Needed for the native build (musl)

#---Build host native rootcling, llvm-tblgen, clang-tblgen for cross-compilation------------------------
if [ $target != $MACHTYPE ]; then 
    # Patch the sources to use the native binary for rootcling
    (cd srcdir/root-*/
        atomic_patch -p2 ../patches/rootcling-cross-compile.patch
    )

    # Build for the host binary native used in second step build process
    mkdir native
    cmake -GNinja -DCMAKE_INSTALL_PREFIX=$prefix \
          -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
          -DLLVM_HOST_TRIPLE=$MACHTYPE \
          -DLLVM_DEFAULT_TARGET_TRIPLE=$target \
          -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF \
          -DCMAKE_PREFIX_PATH=$host_prefix \
          -DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath-link,$host_prefix/lib \
          -Dminimal=ON \
          ${CMAKE_FLAGS[@]} \
          -B native -S srcdir/root-*/
    ninja -C native -j${nproc} rootcling_stage1 rootcling llvm-tblgen clang-tblgen llvm-config llvm-symbolizer

    # Add extra options to use the built native binaries
    CMAKE_EXTRA_OPTS+=(-DNATIVE_BINARY_DIR=$PWD/native)
    CMAKE_EXTRA_OPTS+=(-DLLVM_TABLEGEN=$PWD/native/interpreter/llvm-project/llvm/bin/llvm-tblgen)
    CMAKE_EXTRA_OPTS+=(-DCLANG_TABLEGEN=$PWD/native/interpreter/llvm-project/llvm/bin/clang-tblgen)
    CMAKE_EXTRA_OPTS+=(-DLLVM_CONFIG_PATH=$PWD/native/interpreter/llvm-project/llvm/bin/llvm-config)

    # Define ROOTCLINGNATIVE to use the native rootcling
    export ROOTCLINGNATIVE="env CPLUS_INCLUDE_PATH=${SYSTEM_INCLUDE_PATH} $PWD/native/bin/rootcling"

    # Remove the CPLUS_INCLUDE_PATH environment variable. Was needed for the native build only
    unset CPLUS_INCLUDE_PATH
fi

#---Standard build (cross-compilation)-------------------------------------------------------------
mkdir build
cmake -GNinja \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      ${CMAKE_FLAGS[@]} \
      -Dgminimal=ON \
      ${CMAKE_EXTRA_OPTS[@]} \
      -B build -S srcdir/root-*/
ninja -C build -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms =  [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    # Platform("aarch64", "linux"; libc = "glibc"),
    # Platform("armv6l", "linux", libc = "glibc"),
    # Platform("armv7l", "linux", libc = "glibc"),
    # Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("aarch64", "macos"),
    # Platform("x86_64", "macos"),
] |> expand_cxxstring_abis

# The products that we will ensure are always built
products = [
    LibraryProduct("libCore", :libCore),
    LibraryProduct("libCling", :libCling),
    ExecutableProduct("root", :root),
]

# Some dependencies are needed only on Linux and FreeBSD
x11_platforms = filter(p ->Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms)
    HostBuildDependency("Zlib_jll")
    HostBuildDependency("Zstd_jll")
    HostBuildDependency("Lz4_jll")
    HostBuildDependency("nlohmann_json_jll")
    HostBuildDependency("FreeType2_jll")
    HostBuildDependency("PCRE_jll")
    HostBuildDependency("XZ_jll")
    HostBuildDependency("xxHash_jll")
    Dependency("Zlib_jll")
    Dependency("Zstd_jll")
    Dependency("Lz4_jll")
    Dependency("nlohmann_json_jll")
    Dependency("FreeType2_jll")
    Dependency("PCRE_jll")
    Dependency("XZ_jll")
    Dependency("xxHash_jll")
    Dependency("OpenSSL_jll"; compat="1.1.10")
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms)
    Dependency("Xorg_libXpm_jll"; platforms=x11_platforms)
    Dependency("Xorg_libXft_jll"; platforms=x11_platforms)
    Dependency("Xorg_libICE_jll"; platforms=x11_platforms)
    Dependency("Xorg_libSM_jll"; platforms=x11_platforms)
    Dependency("Xorg_libXfixes_jll"; platforms=x11_platforms)
    Dependency("Xorg_libXi_jll"; platforms=x11_platforms)
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms)
    Dependency("Xorg_libXmu_jll"; platforms=x11_platforms)
    Dependency("Xorg_libXt_jll"; platforms=x11_platforms)
    Dependency("Xorg_libXtst_jll"; platforms=x11_platforms)
    Dependency("Xorg_xcb_util_jll"; platforms=x11_platforms)
    Dependency("Xorg_libxkbfile_jll"; platforms=x11_platforms)
    #Dependency("libLVM_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"11", julia_compat="1.6")
