# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "WrapIt"
version = v"1.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/grasph/wrapit.git", "85276a28d1d1d0f7719d7d798534bb265f462606")
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")
]

# Bash recipe for building across all platforms
script = raw"""
# Default binarybuilder darwin chaintools miss support for filesytem
# Install a newer SDK which supports following the recipee from
# https://github.com/JuliaPackaging/Yggdrasil/pull/2741
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -rp usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -rp System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

######################################################################
# Build the software
clang_resource_dir=clang/res
cd "$WORKSPACE/srcdir"
mkdir build
cd build/
cmake -GNinja -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN -DCMAKE_BUILD_TYPE=Release -DCMAKE_CROSSCOMPILING=True -DCLANG_JLL=True -DCLANG_RESOURCE_DIR="$clang_resource_dir" ../wrapit/
cmake --build .
cmake --install .
#
######################################################################

######################################################################
# Install dependencies for the wrapit executable to ship with the tarball
[ "$dlext" = dll ] && (cd $prefix/lib && ln -s libLLVM-*.dll.a libLLVM.dll.a )

cd "$(readlink -f "$prefix")"
 if [ "${dlext}" = dylib ]; then
   clangversiontag=
   llvmversiontag=
 else
   clangversiontag=".16jl"
   llvmversiontag=`echo $clangversiontag | sed 's/^\./-/'` #.16jl -> -16jl
 fi
 clanglib=libclang.$dlext$clangversiontag
 clangcpplib=libclang-cpp.$dlext$clangversiontag
 llvmlib=libLLVM$llvmversiontag.${dlext}

 clang_uuid="`echo ../artifacts/*/lib/$clanglib | head -n 1 | sed 's|^../artifacts/\([^/[:space:]]*\).*|\1|'`"
 llvm_uuid="`echo ../artifacts/*/lib/$llvmlib | head -n 1 | sed 's|^../artifacts/\([^/[:space:]]*\).*|\1|'`"

 if echo "$clang_uuid $llvm_uuid" | grep -q '*'; then
    echo "Failed to find clang or llvm library." 1>&1
    false
 fi

 cat <<EOF 1>&2
Clang artifact uuid: $clang_uuid
LLVM artifact uuid: $llvm_uuid
EOF

# Add a link to the clang resource directory
ln -sf artifacts/$clang_uuid ..
mkdir -p lib/$clang_resource_dir
cp -rp ../artifacts/$clang_uuid/lib/clang/16/include lib/"$clang_resource_dir"

# Add libraries used by wrapit. Make copy as we haven't found how
# To get symlinks to regular files included in the genrated tarball.
rm "lib/$clanglib"
cp -p "../artifacts/$clang_uuid/lib/$clanglib" lib/
rm "lib/$clangcpplib"
cp -p "../artifacts/$clang_uuid/lib/$clangcpplib" lib/
rm "lib/$llvmlib"
cp -p "../artifacts/$llvm_uuid/lib/$llvmlib" lib/
#
######################################################################

install_license "${WORKSPACE}/srcdir/wrapit/LICENSE"
"""

# LLVM_jll not available for i686+musl (see https://github.com/JuliaPackaging/Yggdrasil/blob/f756bd9eb500ad68a8b8bb4413d6692c8e766a47/L/LLVM/common.jl)
# Windows not supported:
platform_veto(p) = Sys.iswindows(p) || (arch(p) == "i686" && libc(p) == "musl")

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude = platform_veto)
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("wrapit", :wrapit)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
    BuildDependency(PackageSpec(name="Clang_jll", uuid="0ee61d77-7f21-5576-8119-9fcc46b10100"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
