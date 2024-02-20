# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROOT"
version = v"6.30.04"

rootgithash = Dict(v"6.30.4" => "ebd5b65997c3dff10fc38472a40ddffc26fb982a")

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/root-project/root.git", rootgithash[version])
]

# Bash recipe for building across all platforms
script = raw"""

if echo "$target" | grep musl; then #build wih musl library
# Disabling what is not working with musl:
    CMAKE_EXTRA_OPTS="-Ddavix=OFF -Dxrootd=OFF -Dssl=OFF"
fi

# build-in compilation of the libAfterImage library needs this directory
mkdir -p /tmp/user/0

cd $WORKSPACE/srcdir

# For the cross-compiling, LLVM needs to compile the llvm-tblgen tool
# for the host. The ROOT LLVM code tree does not include the test and
# benchmark directories cmake will need to configure for the host for
# this bootstrap. We need to disable the build of the test and benchmarks
sed -i 's/\(option(LLVM_INCLUDE_TESTS[[:space:]].*[[:space:]]\)on)\(.*\)/\1OFF)\2/i
        s/\(option(LLVM_INCLUDE_BENCHMARKS[[:space:]].*[[:space:]]\)on)\(.*\)/\1OFF)\2/i' \
        root/interpreter/llvm-project/llvm/CMakeLists.txt

# N llvm links. LLVM link command needs 15GB
LLVM_PARALLEL_LINK_JOBS=`grep MemTot /proc/meminfo  | awk '{a=int($2/15100000); if(a>'"$nproc"') a='"$nproc"'; if(a<1) a=1; print a;}'`

# For the rootcling execution performed during the build:
echo "include_directories(SYSTEM /opt/$target/$target/sys-root/usr/include)" >> ${CMAKE_TARGET_TOOLCHAIN}

# Build with debug info, while we are debugging this script:
BUILD_TYPE=Debug

cmake -GNinja \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DLLVM_PARALLEL_LINK_JOBS=$LLVM_PARALLEL_LINK_JOBS \
      $CMAKE_EXTRA_OPTS \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DLLVM_BUILD_TYPE=$BUILD_TYPE \
      -B build -S root

cmake --build build -j${nproc} 
cmake --install build --prefix $prefix
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    # Platform("aarch64", "linux"; libc = "glibc"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    # Platform("powerpc64le", "linux"; libc = "glibc"),
    # Platform("i686", "linux"; libc = "musl"),
    # Platform("x86_64", "linux"; libc = "musl"),
    # Platform("aarch64", "linux"; libc = "musl"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    #Mandatory dependencies
    BuildDependency("Xorg_xorgproto_jll")
    Dependency("Xorg_libX11_jll")
    Dependency("Xorg_libXpm_jll")
    Dependency("Xorg_libXft_jll")    

    #Optionnal dependencies (if absent, either a feature will be disabled or a built-in version will be compiled)
    Dependency("VDT_jll")
    Dependency("XRootD_jll")
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency("Lz4_jll")
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="Giflib_jll", uuid="59f7168a-df46-5410-90c8-f2779963d0ec"))
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4"))
    Dependency(PackageSpec(name="PCRE_jll", uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc"))
    Dependency(PackageSpec(name="Graphviz_jll", uuid="3c863552-8265-54e4-a6dc-903eb78fde85"))
    Dependency(PackageSpec(name="xxHash_jll", uuid="5fdcd639-92d1-5a06-bf6b-28f2061df1a9"))
    Dependency("XZ_jll")
    Dependency(PackageSpec(name="Librsvg_jll", uuid="925c91fb-5dd6-59dd-8e8c-345e74382d89"))
    Dependency("FreeType2_jll")
    Dependency("Xorg_libICE_jll")
    Dependency("Xorg_libSM_jll")
    Dependency("Xorg_libXfixes_jll")
    Dependency("Xorg_libXi_jll")
    Dependency("Xorg_libXinerama_jll")
    Dependency("Xorg_libXmu_jll")
    Dependency("Xorg_libXt_jll")
    Dependency("Xorg_libXtst_jll")
    Dependency("Xorg_xcb_util_jll")
    Dependency("Xorg_libxkbfile_jll")
    Dependency("Libglvnd_jll")
    Dependency("OpenBLAS_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
