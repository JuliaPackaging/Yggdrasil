
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROOT"
version = v"6.30.04"

rootgithash = Dict(v"6.30.4" => "ebd5b65997c3dff10fc38472a40ddffc26fb982a")

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/root-project/root.git", rootgithash[version]),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE
cat > script.sh <<EOF
if echo "\$target" | grep -q musl; then #build wih musl library
# Disabling what is not working with musl:
    CMAKE_EXTRA_OPTS="-Ddavix=OFF -Dxrootd=OFF -Dssl=OFF -Druntime_cxxmodules=OFF -Droofit=OFF"
else
    CMAKE_EXTRA_OPTS=-Druntime_cxxmodules=OFF
fi

#Uncomment for a minimal build for debugging purposes
#CMAKE_EXTRA_OPTS="\$CMAKE_EXTRA_OPTS -Dclad=OFF -Dhtml=OFF -Dwebgui=OFF -Dcxxmodules=OFF -Dproof=OFF -Dtmva=OFF -Drootfit=OFF -Dxproofd=OFF -Dxrootd=OFF -Dssl=OFF -Dpyroot=OFF -Dtesting=OFF -Droot7=OFF -Dspectrum=OFF -Dunfold=OFF -Dasimage=OFF -Dgviz=OFF -Dfitiso=OFF -Dcocoa=OFF -Dopengl=OFF -Dproof=OFF -Dxml=OFF -Dgfal=OFF -Dmpi=OFF"

export SYSTEM_INCLUDE_PATH="\`\$target-g++ --sysroot="/opt/\$target/\$target/sys-root" -E -x c++ -v /dev/null  2>&1  | awk '{gsub("^ ", "")} /End of search list/{a=0} {if(a==1){s=s d \$0;d=":"}} /#include <...> search starts here/{a=1} END{print s}'\`"

# build-in compilation of the libAfterImage library needs this directory
mkdir -p /tmp/user/0

cd /
[ -f /opt/bin/x86_64-linux-gnu-libgfortran5-cxx11/x86_64-linux-gnu-g++ ] && atomic_patch -p1 \${WORKSPACE}/srcdir/patches/x86_64-linux-gnu-g++.patch

cd "\$WORKSPACE"

# For the cross-compiling, LLVM needs to compile the llvm-tblgen tool
# for the host. The ROOT LLVM code tree does not include the test and
# benchmark directories cmake will need to configure for the host for
# this bootstrap. Therefore, we need to disable the build of the test and
# benchmarks.
sed -i 's/\(option(LLVM_INCLUDE_TESTS[[:space:]].*[[:space:]]\)on)\(.*\)/\1OFF)\2/i
        s/\(option(LLVM_INCLUDE_BENCHMARKS[[:space:]].*[[:space:]]\)on)\(.*\)/\1OFF)\2/i' \\
        srcdir/root/interpreter/llvm-project/llvm/CMakeLists.txt
echo "set(CXX_STANDARD 17)" >> srcdir/root/interpreter/llvm-project/llvm/CMakeLists.txt

# N llvm links. LLVM link command needs 15GB
njobs=\$((2*\`nproc\`))
LLVM_PARALLEL_LINK_JOBS=\`grep MemTot /proc/meminfo  | awk '{a=int(\$2/15100000); if(a>'"\$njobs"') a='"\$njobs"'; if(a<1) a=1; print a;}'\`

#DEBUG# # For the rootcling execution performed during the build:
#DEBUG# echo "include_directories(SYSTEM /opt/\$target/\$target/sys-root/usr/include)" >> \${CMAKE_TARGET_TOOLCHAIN}

# Build with debug info, while we are debugging this script:
BUILD_TYPE=Debug

# Support to run programs linked with glibc
#if [ $target = x86_64-linux-gnu ]; then
#   ln -sf /opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
#fi

#For gcc 9.1.0 (bug fixed with 9.3.0)
#(cd / && atomic_patch -p1 \${WORKSPACE}/srcdir/patches/\$target-variant.patch)

if [ $target != $MACHTYPE ]; then #cross compilation

   (cd srcdir
   # patch to fix cross-compilation with rootcling
   #atomic_patch -p1 patches/rootcling-cross-compile.patch
   atomic_patch -p1 patches/rootcling-cross-compile-v3.patch

   # patch to fix cross-compilation for afterimage
   atomic_patch -p1 patches/afterimage-cross-compile.patch
   )

   #sed -i 's@set(command \${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=\${CMAKE_BINARY_DIR}/lib:.*" \$<TARGET_FILE:rootcling_stage1>)@set(command \${CMAKE_COMMAND} -E env "LD_LIBRARY_PATH=\${CMAKE_BINARY_DIR}/lib:\$ENV{WORKSPACE}/x86_64-linux-gnu-libgfortran5-cxx11/destdir/lib" LLVM_SYMBOLIZER_PATH=\${CMAKE_BINARY_BUILD}/interpreter/llvm-project/llvm/NATIVE/tools/llvm-symbolizer \$<TARGET_FILE:rootcling_stage1>)@' \${WORKSPACE}/srcdir/root/cmake/modules/RootMacros.cmake

   # Compile for the host binary used in the build process
   mkdir NATIVE
   cmake -GNinja \\
         -DCMAKE_TOOLCHAIN_FILE=\${CMAKE_HOST_TOOLCHAIN} \\
         -DLLVM_HOST_TRIPLE=\$MACHTYPE \\
         -DLLVM_PARALLEL_LINK_JOBS=\$LLVM_PARALLEL_LINK_JOBS \\
         -DCXX_STANDARD=c++17 \\
         -DCLANG_DEFAULT_STD_CXX=cxx17 \\
         \$CMAKE_EXTRA_OPTS \\
         -DCMAKE_BUILD_TYPE=Release \\
         -DCLING_CXX_PATH=g++ \\
         -B NATIVE -S srcdir/root

   ninja -C NATIVE -j\${njobs} rootcling_stage1 llvm-tblgen clang-tblgen llvm-config llvm-symbolizer

   CMAKE_EXTRA_OPTS="\$CMAKE_EXTRA_OPTS -DNATIVE_BINARY_DIR=\$PWD/NATIVE \\
      -DLLVM_TABLEGEN=\"\$PWD/NATIVE/interpreter/llvm-project/llvm/bin/llvm-tblgen\" \\
      -DCLANG_TABLEGEN=\"\$PWD/NATIVE/interpreter/llvm-project/llvm/bin/clang-tblgen\" \\
      -DLLVM_CONFIG_PATH=\"\$PWD/NATIVE/interpreter/llvm-project/llvm/bin/llvm-config\""
fi

# CPLUS_INCLUDE_PATH used to set system include path for rootcling in absence
# of a -sysroot option. It should be transparent gcc and target build as it set the path 
# to the value obtained from gcc itself before setting CPLUS_INCLUDE_PATH and using
# the same sysroot option as for compilation.
export CPLUS_INCLUDE_PATH="\$SYSTEM_INCLUDE_PATH"
mkdir build
cmake -GNinja \\
      -DCMAKE_TOOLCHAIN_FILE=\${CMAKE_TARGET_TOOLCHAIN} \\
      -DCMAKE_INSTALL_PREFIX=\$prefix \\
      -DLLVM_HOST_TRIPLE=\$target \\
      -DLLVM_PARALLEL_LINK_JOBS=\$LLVM_PARALLEL_LINK_JOBS \\
      -DCXX_STANDARD=c++17 \\
      -DCLANG_DEFAULT_STD_CXX=cxx17 \\
      \$CMAKE_EXTRA_OPTS \\
      -DCMAKE_BUILD_TYPE=\$BUILD_TYPE -DLLVM_BUILD_TYPE=\$BUILD_TYPE \\
      -DCLING_CXX_PATH=g++ \\
      -B build -S srcdir/root

# Build the code
cmake --build build -j\${njobs}

# Install the binaries
cmake --install build --prefix \$prefix
cp -a build/core/rootcling_stage1/src/rootcling_stage1 \$prefix/bin/
EOF
bash -x -e script.sh
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
    ExecutableProduct("root", :root)
    ExecutableProduct("rootcling", :rootcling)
    ExecutableProduct("rootcling_stage1", :rootcling_stage1)
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
    Dependency("oneTBB_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")
