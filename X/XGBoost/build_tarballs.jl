using BinaryBuilder, Pkg

# Collection of sources required to build XGBoost
name = "XGBoost"
version = v"1.6.1"
sources = [
    GitSource("https://github.com/dmlc/xgboost.git","5d92a7d936fc3fad4c7ecb6031c3c1c7da882a14"), 
    DirectorySource("./bundled"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
    "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

# Patch dmlc-core to use case-sensitive windows.h includes
(cd dmlc-core; atomic_patch -p1 "${WORKSPACE}/srcdir/patches/dmlc_windows.patch")

# For Linux, build using CMake
if [[ ${target} == *linux* ]] ||  [[ ${target} == *mingw* ]]; then
    (mkdir build; cd build; cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}")
    make -C build -j ${nproc}
# For ARM64 Mac and FreeBSD, build without openmp
elif [[ ${target} == aarch64-apple-darwin* ]] ||  [[ ${target} == *freebsd* ]]; then
    (mkdir build; cd build; cmake .. -DUSE_OPENMP=OFF -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}")
    make -C build -j ${nproc}
# For x86_64 Mac, build without openmp
elif [[ "${target}" == x86_64-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.15
    #install a newer SDK which supports `___cxa_deleted_virtual`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    (mkdir build; cd build; cmake .. -DUSE_OPENMP=OFF -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}")
    make -C build -j ${nproc}
fi

# Install
mkdir -p ${prefix}/{bin,include,lib}
cp -ra include/xgboost ${prefix}/include/
cp -a xgboost${exeext} ${prefix}/bin/xgboost${exeext}

if [[ ${target} == *mingw* ]]; then
    cp -a lib/xgboost.dll ${prefix}/bin
else
    cp -a lib/libxgboost.${dlext} ${prefix}/lib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
    ExecutableProduct("xgboost", :xgboost)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
