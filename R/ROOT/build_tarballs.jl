# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

using BinaryBuilder, Pkg

name = "ROOT"
version = v"6.32.8"

rootgithash = Dict(v"6.32.6" => "5380676d1f0ed3055048f305de917572f976a090",
                   v"6.32.8" => "a1748a069d2d5f27ec528cfd89b54b12dcba793e")


# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/root-project/root.git", rootgithash[version]),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

echo USE_CCACHE: $USE_CCACHE

cd $WORKSPACE
if echo "$target" | grep -q musl; then #build wih musl library
# Disabling what is not working with musl:
    CMAKE_EXTRA_OPTS=(-Ddavix=OFF -Dxrootd=OFF -Dssl=OFF -Druntime_cxxmodules=OFF -Droofit=OFF)
else
    CMAKE_EXTRA_OPTS=(-Druntime_cxxmodules=OFF)
fi

# Required to compile graf3d/ftgl/src/FTVectoriser.cxx (for gcc to accept a conversion from char* to unsigned char*)
CMAKE_EXTRA_OPTS+=(-DCMAKE_CXX_FLAGS=-fpermissive)

# Uncomment for a minimal build for debugging purposes
#CMAKE_EXTRA_OPTS+=(-Dclad=OFF -Dhtml=OFF -Dwebgui=OFF -Dcxxmodules=OFF -Dproof=OFF -Dtmva=OFF -Drootfit=OFF -Dxproofd=OFF -Dxrootd=OFF -Dssl=OFF -Dpyroot=OFF -Dtesting=OFF -Droot7=OFF -Dspectrum=OFF -Dunfold=OFF -Dasimage=OFF -Dgviz=OFF -Dfitiso=OFF -Dcocoa=OFF -Dopengl=OFF -Dproof=OFF -Dxml=OFF -Dgfal=OFF -Dmpi=OFF)

export SYSTEM_INCLUDE_PATH="`g++ --sysroot="/opt/$target/$target/sys-root" -E -x c++ -v /dev/null  2>&1  | awk '{gsub(\"^ \", \"\")} /End of search list/{a=0} {if(a==1){s=s d $0;d=":"}} /#include <...> search starts here/{a=1} END{print s}'`"

# build-in compilation of the libAfterImage library needs this directory
mkdir -p /tmp/user/0

cd /

cd "$WORKSPACE"

# For the cross-compiling, LLVM needs to compile the llvm-tblgen tool
# for the host. The ROOT LLVM code tree does not include the test and
# benchmark directories cmake will need to configure for the host for
# this bootstrap. Therefore, we need to disable the build of the test and
# benchmarks.
sed -i 's/\(option(LLVM_INCLUDE_TESTS[[:space:]].*[[:space:]]\)on)\(.*\)/\1OFF)\2/i
        s/\(option(LLVM_INCLUDE_BENCHMARKS[[:space:]].*[[:space:]]\)on)\(.*\)/\1OFF)\2/i' \
        srcdir/root/interpreter/llvm-project/llvm/CMakeLists.txt
echo "set(CXX_STANDARD 17)" >> srcdir/root/interpreter/llvm-project/llvm/CMakeLists.txt

# N llvm links. LLVM link command needs 15GB
njobs=${nproc}
LLVM_PARALLEL_LINK_JOBS=`grep MemTot /proc/meminfo  | awk '{a=int($2/15100000); if(a>'"$njobs"') a='"$njobs"'; if(a<1) a=1; print a;}'`

# For the rootcling execution performed during the build:
echo "include_directories(SYSTEM /opt/$target/$target/sys-root/usr/include)" >> ${CMAKE_TARGET_TOOLCHAIN}

# Build with or without debug information: Debug / Release
BUILD_TYPE=Release

#Patch needed for gcc [9.1.0, 9.3.0)
cat <<EOF | gcc -x c -o need_variant_patch -
int main(){
  long vers = __GNUC__ * 10000 + __GNUC_MINOR__ * 100 + __GNUC_PATCHLEVEL__;
  return (90100 <= vers && vers < 90300) ? 0 : 1;
}
EOF

./need_variant_patch && (cd / && atomic_patch -p1 ${WORKSPACE}/srcdir/patches/$target-variant.patch)

if [ $target != $MACHTYPE ]; then #cross compilation

   (cd srcdir
   # patch to fix cross-compilation with rootcling
   atomic_patch -p1 patches/rootcling-cross-compile_""" * string(version) * raw""".patch

   # patch to fix cross-compilation for afterimage
   atomic_patch -p1 patches/afterimage-cross-compile.patch
   )

   # Compile for the host binary used in the build process
   # Davix is switched off, as otherwise build fails in buildkite CI. It should not be
   # needed for the NATIVE tools. 
   mkdir NATIVE
   cmake -GNinja \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
         -DLLVM_HOST_TRIPLE=$MACHTYPE \
         -DLLVM_PARALLEL_LINK_JOBS=$LLVM_PARALLEL_LINK_JOBS \
         -DCXX_STANDARD=c++17 \
         -DCLANG_DEFAULT_STD_CXX=cxx17 \
         "${CMAKE_EXTRA_OPTS[@]}" \
         -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DLLVM_BUILD_TYPE=$BUILD_TYPE \
         -DCLING_CXX_PATH=g++ \
         -DCLING_TARGET_GLIBC=1 \
         -DCLING_TARGET_GLIBCXX=1 \
         -DCLING_SYSTEM_INCLUDE_PATH="$SYSTEM_INCLUDE_PATH" \
         -Ddavix=OFF \
         -B NATIVE -S srcdir/root

   cmake --build NATIVE -- -j$njobs rootcling_stage1 rootcling llvm-tblgen clang-tblgen llvm-config llvm-symbolizer

   CMAKE_EXTRA_OPTS+=($CMAKE_EXTRA_OPTS "-DNATIVE_BINARY_DIR=$PWD/NATIVE" \
      "-DLLVM_TABLEGEN=$PWD/NATIVE/interpreter/llvm-project/llvm/bin/llvm-tblgen" \
      "-DCLANG_TABLEGEN=$PWD/NATIVE/interpreter/llvm-project/llvm/bin/clang-tblgen" \
      "-DLLVM_CONFIG_PATH=$PWD/NATIVE/interpreter/llvm-project/llvm/bin/llvm-config" \
      "-DCLING_SYSTEM_INCLUDE_PATH=$SYSTEM_INCLUDE_PATH")
fi

# CPLUS_INCLUDE_PATH used to set system include path for rootcling in absence
# of a -sysroot option. It should be transparent gcc and target build as it set the path 
# to the value obtained from gcc itself before setting CPLUS_INCLUDE_PATH and using
# the same sysroot option as for compilation.
export CPLUS_INCLUDE_PATH="$SYSTEM_INCLUDE_PATH"
mkdir build
cmake -GNinja \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DLLVM_HOST_TRIPLE=$target \
      -DLLVM_PARALLEL_LINK_JOBS=$LLVM_PARALLEL_LINK_JOBS \
      -DCXX_STANDARD=c++17 \
      -DCLANG_DEFAULT_STD_CXX=cxx17 \
      "${CMAKE_EXTRA_OPTS[@]}" \
      -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DLLVM_BUILD_TYPE=$BUILD_TYPE \
      -DCLING_CXX_PATH=g++ \
      -Dfound_urandom_EXITCODE=0 \
      -Dfound_urandom_EXITCODE__TRYRUN_OUTPUT="" \
      -B build -S srcdir/root

# Build the code
cmake --build build -j${njobs}

# Install the binaries
cmake --install build --prefix $prefix
install -Dvm 755 build/core/rootcling_stage1/src/rootcling_stage1 -t "${bindir}"
"""

# Add to the recipe script commands to write the recipe in a file into the sandbox
# to ease debugging with the --debug build_tarballs.jl option.
scriptwrapper = """
cat > "\$WORKSPACE/recipe.sh" <<END_OF_SCRIPT
$(replace(script, "\\" => "\\\\", "\$" => "\\\$", "`" => "\\`"))
END_OF_SCRIPT

chmod a+x "\$WORKSPACE/recipe.sh"
$script
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
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"))
    Dependency(PackageSpec(name="Xorg_libXpm_jll", uuid="1a3ddb2d-74e3-57f3-a27b-e9b16291b4f2"))
    Dependency(PackageSpec(name="Xorg_libXft_jll", uuid="2c808117-e144-5220-80d1-69d4eaa9352c"))

    #Optionnal dependencies (if absent, either a feature will be disabled or a built-in version will be compiled)
    Dependency(PackageSpec(name="VDT_jll", uuid="474730fa-5ea9-5b8c-8629-63de62f23418"))
    Dependency(PackageSpec(name="XRootD_jll", uuid="b6113df7-b24e-50c0-846f-35a2e36cb9d5"))
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="Giflib_jll", uuid="59f7168a-df46-5410-90c8-f2779963d0ec"))
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4"))
    Dependency(PackageSpec(name="PCRE2_jll", uuid="efcefdf7-47ab-520b-bdef-62a2eaa19f15"))
    Dependency(PackageSpec(name="Graphviz_jll", uuid="3c863552-8265-54e4-a6dc-903eb78fde85"))
    Dependency(PackageSpec(name="xxHash_jll", uuid="5fdcd639-92d1-5a06-bf6b-28f2061df1a9"))
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800"))
    Dependency(PackageSpec(name="Librsvg_jll", uuid="925c91fb-5dd6-59dd-8e8c-345e74382d89"))
    Dependency(PackageSpec(name="FreeType2_jll", uuid="d7e528f0-a631-5988-bf34-fe36492bcfd7"))
    Dependency(PackageSpec(name="Xorg_libICE_jll", uuid="f67eecfb-183a-506d-b269-f58e52b52d7c"))
    Dependency(PackageSpec(name="Xorg_libSM_jll", uuid="c834827a-8449-5923-a945-d239c165b7dd"))
    Dependency(PackageSpec(name="Xorg_libXfixes_jll", uuid="d091e8ba-531a-589c-9de9-94069b037ed8"))
    Dependency(PackageSpec(name="Xorg_libXi_jll", uuid="a51aa0fd-4e3c-5386-b890-e753decda492"))
    Dependency(PackageSpec(name="Xorg_libXinerama_jll", uuid="d1454406-59df-5ea1-beac-c340f2130bc3"))
    Dependency(PackageSpec(name="Xorg_libXmu_jll", uuid="6bc1fdef-f8f4-516b-84c1-6f5f86a35b20"))
    Dependency(PackageSpec(name="Xorg_libXt_jll", uuid="28c4a263-0105-5ca0-9a8c-f4f6b89a1dd4"))
    Dependency(PackageSpec(name="Xorg_libXtst_jll", uuid="b6f176f1-7aea-5357-ad67-1d3e565ea1c6"))
    Dependency(PackageSpec(name="Xorg_xcb_util_jll", uuid="2def613f-5ad1-5310-b15b-b15d46f528f5"))
    Dependency(PackageSpec(name="Xorg_libxkbfile_jll", uuid="cc61e674-0454-545c-8b26-ed2c68acab7a"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    Dependency(PackageSpec(name="GLU_jll", uuid="bd17208b-e95e-5925-bf81-e2f59b3e5c61"))
    Dependency(PackageSpec(name="GLEW_jll", uuid="bde7f898-03f7-559e-8810-194d950ce600"))
    Dependency(PackageSpec(name="CFITSIO_jll", uuid="b3e40c51-02ae-5482-8a39-3ace5868dcf4"))
    Dependency(PackageSpec(name="oneTBB_jll", uuid="1317d2d5-d96f-522e-a858-c73665f53c3e"), compat="2021.9.0")
    Dependency(PackageSpec(name="OpenBLAS32", uuid="51095b67-9e93-468d-a683-508b52f74e81"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, scriptwrapper, platforms, products,
               dependencies; julia_compat="1.6", preferred_gcc_version=v"9", lock_microarchitecture=false)

