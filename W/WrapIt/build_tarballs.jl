# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
name = "WrapIt"
version = v"1.5.0"

#Clang_jll version used for the build. Required clang libraries will be shipped with the package.
clang_vers=v"13.0.1+3"
clang_vers_maj=string(clang_vers.major)
clang_patch="$(clang_vers.major).$(clang_vers.minor).$(clang_vers.patch)"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/grasph/wrapit.git", "2c86cf3d33f65055836cb4a600daf24b960229db")
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")
]

# Bash recipe for building across all platforms
script = raw"""
set -x
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

# Search for libcrypto.$dlext which can be in /workspace/destdir/lib ($libdir) or /workspace/destdir/lib64
if [ -f "$libdir/libcrypto.$dlext" ]; then
  libcrypto_path="$libdir/libcrypto.$dlext"
elif [ -f "${libdir}/../lib64/libcrypto.$dlext" ]; then
  libcrypto_path="${libdir}/../lib64/libcrypto.$dlext"
else
  echo "libcrypto.$dlext not found"
  exit 1
fi

######################################################################
# Build the software
clang_resource_dir=clang/res
cd "$WORKSPACE/srcdir"
mkdir build
cd build/
cmake -GNinja \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
-DCMAKE_BUILD_TYPE=Release \
-DCLANG_JLL=True \
-DOPENSSL_USE_STATIC_LIBS=True \
-DCLANG_RESOURCE_DIR="$clang_resource_dir" \
-DOPENSSL_ROOT_DIR="$prefix" -DOPENSSL_CRYPTO_LIBRARY="${libcrypto_path}" \
../wrapit/
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
   clangversiontag=".""" * clang_vers_maj * raw"""jl"
   llvmversiontag=`echo $clangversiontag | sed 's/^\./-/'` #.NNjl -> -NNjl
 fi
 clanglib=libclang.$dlext$clangversiontag
 if  [ $clanglib=libclang.so.13jl ] && ! [ -f $libdir/libclang.so.13jl ] && [ -f $libdir/libclang.so.13 ]; then
    clanglib=libclang.so.13
 fi
 clangcpplib=libclang-cpp.$dlext$clangversiontag
 llvmlib=libLLVM$llvmversiontag.${dlext}

 echo "Looking for ../artifacts/*/lib/$clanglib and ../artifacts/*/lib/$llvmlib" 1>&2

 clang_search="../artifacts/*/lib/$clanglib"
 llvm_search="../artifacts/*/lib/$llvmlib"
 clang_uuid="`echo $clang_search | head -n 1 | sed 's|^../artifacts/\([^/[:space:]]*\).*|\1|'`"
 llvm_uuid="`echo $llvm_search | head -n 1 | sed 's|^../artifacts/\([^/[:space:]]*\).*|\1|'`"

 ret=0
 if echo "$clang_uuid" | grep -q '*'; then
    echo "Failed to find clang library under path $clang_search" 1>&2
    ret=1
 fi

 if echo "$llvm_uuid" | grep -q '*'; then
    echo "Failed to find llvm library under path $llvm_search" 1>&2
    ret=1
 fi

 #trigger exit if at least one of the two library was not found
 [ $ret = 0 ] || false

 cat <<EOF 1>&2
Clang artifact uuid: $clang_uuid
LLVM artifact uuid: $llvm_uuid
EOF

# Add a link to the clang resource directory
ln -sf artifacts/$clang_uuid ..
mkdir -p lib/$clang_resource_dir
if [ -f ../artifacts/$clang_uuid/lib/clang/""" * clang_vers_maj * raw""" ]; then
    cp -rp ../artifacts/$clang_uuid/lib/clang/""" * clang_vers_maj * raw"""/include lib/"$clang_resource_dir"
else
    cp -rp ../artifacts/$clang_uuid/lib/clang/""" * clang_patch * raw"""/include lib/"$clang_resource_dir"
fi

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
    BuildDependency(PackageSpec(name="Clang_jll", uuid="0ee61d77-7f21-5576-8119-9fcc46b10100", version=clang_vers))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"), compat="3.0.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
