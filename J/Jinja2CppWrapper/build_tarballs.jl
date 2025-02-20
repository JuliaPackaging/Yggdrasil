# Note: this script will require BinaryBuilder.jl v0.3.0 or greater
using BinaryBuilder, Pkg

name = "Jinja2CppWrapper"
version = v"1.3.2"
# Collection of sources required to build ITKWrapper
sources = [
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz", 
        "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    DirectorySource("./src"),
]

# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)
# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

# Bash recipe for building across all platforms
script = raw"""
mkdir -p build/

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    commonoptions=" \
        -opensource -confirm-license \
        -openssl-linked  -nomake examples -release \
        "
    commoncmakeoptions="-DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DQT_HOST_PATH=$host_prefix -DQT_FEATURE_openssl_linked=ON"
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    deployarg="-DCMAKE_OSX_DEPLOYMENT_TARGET=12"
    export LDFLAGS="-L${libdir}/darwin -lclang_rt.osx"
    export MACOSX_DEPLOYMENT_TARGET=12
    export OBJCFLAGS="-D__ENVIRONMENT_OS_VERSION_MIN_REQUIRED__=120000"
    export OBJCXXFLAGS=$OBJCFLAGS
    export CXXFLAGS=$OBJCFLAGS
    sed -i 's/exit 1/#exit 1/' /opt/bin/$bb_full_target/$target-clang++
    ../qtbase-everywhere-src-*/configure -prefix $prefix $commonoptions -- $commoncmakeoptions \
        -DQT_INTERNAL_APPLE_SDK_VERSION=14 -DQT_INTERNAL_XCODE_VERSION=15 -DCMAKE_SYSROOT=$apple_sdk_root \
        -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks $deployarg \
        -DCUPS_INCLUDE_DIR=$apple_sdk_root/usr/include -DCUPS_LIBRARIES=$apple_sdk_root/usr/lib/libcups.tbd \
        -DQT_FEATURE_vulkan=OFF 
    sed -i 's/#exit 1/exit 1/' /opt/bin/$bb_full_target/$target-clang++
fi

cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    ..

cmake --build build --parallel ${nproc}
cmake --install build
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjinja2cpp_wrapper", :libjinja2cpp_wrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Jinja2Cpp_jll", uuid="72923777-883d-5a9e-8d94-bec813f4d578")),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"); compat = "0.13.4"),
    BuildDependency(PackageSpec(name="libjulia_jll", uuid="5ad3ddd2-0711-543a-b040-befd59781bbf")),
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p) || Sys.iswindows(p), platforms)),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")
