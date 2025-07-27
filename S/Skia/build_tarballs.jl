# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Skia"
version = v"0.40.1"

# Collection of sources required to complete build
sources = [
   GitSource("https://github.com/google/skia.git", "482de011c920d85fdbe21a81c45852655df6a809"),
   GitSource("https://github.com/stensmo/cskia.git", "7790e8f426cec7ad620cd04a04f28f604751e8d1"),
   DirectorySource("./bundled"),
   # Missing header ft2build.h for freetype2
   GitSource("https://chromium.googlesource.com/chromium/src/third_party/freetype2.git","5d4e649f740c675426fbe4cdaffc53ee2a4cb954"),
   GitSource("https://chromium.googlesource.com/libyuv/libyuv.git","d248929c059ff7629a85333699717d7a677d8d96"),
   # These two have some kind of source dependency. 
   GitSource("https://skia.googlesource.com/external/github.com/google/wuffs-mirror-release-c.git","e3f919ccfe3ef542cfc983a82146070258fb57f8"),
   GitSource("https://chromium.googlesource.com/chromium/src/third_party/zlib","646b7f569718921d7d4b5b8e22572ff6c76f2596"),
   # Need 10.15 SDK for Mac
   FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz","2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]



# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !Sys.iswindows(p), platforms)
platforms = expand_cxxstring_abis(platforms)

# Remove musl && cxx03, since there is a bug preventing Skia to build
filter!(p -> !(cxxstring_abi(p) == "cxx03" && libc(p) == "musl"), platforms)



# The products that we will ensure are always built
products = [
    LibraryProduct("libskia", :libskia)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Fontconfig_jll"; compat="2.16.0")
    Dependency("JpegTurbo_jll"; compat="3.1.1")
    Dependency("libpng_jll"; compat="1.6.49")
    Dependency("libwebp_jll"; compat="1.5.0")
    Dependency("ICU_jll"; compat="76.1")
    Dependency("Expat_jll"; compat="2.6.5")
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc");)
    Dependency(PackageSpec(name="xkbcommon_jll", uuid="d8fb68d0-12a3-5cfd-a85a-d49703b185fd"); )
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"); )
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b");)
]



# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

mkdir skia/third_party/externals/
shopt -s extglob

# Rename libraries to the names used in Skia
mv wuffs-mirror-release-c wuffs
mv freetype2 freetype

# Move dependencies to the correct location
mv !(cskia|skia|patches|MacOSX10.15.sdk.tar.xz) skia/third_party/externals/


cd skia

install_license LICENSE 

bin/fetch-gn 


cp ../cskia/capi/sk_capi.cpp src/base/
cp ../cskia/capi/sk_capi.h src/base/


if [[ "${target}" == x86_64-* ]]; then
    target_cpu=x64
elif [[ "${target}" == aarch64-* ]]; then
    target_cpu=arm64
elif [[ "${target}" == riscv64-* ]]; then
    target_cpu=riscv
elif [[ "${target}" == powerpc64le-* ]]; then
    target_cpu=powerpc64le
elif [[ "${target}" == i686-* ]]; then
    target_cpu=x86
elif [[ "${target}" == armv7l-* ]]; then
    target_cpu=armv7-a
elif [[ "${target}" == armv6l-* ]]; then
    target_cpu=arm
fi


if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Work around the issue
    export MACOSX_DEPLOYMENT_TARGET=10.15
    # ...and install a newer SDK
    rm -rf /opt/${target}/${target}/sys-root/System
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX10.15.sdk.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX10.15.sdk/System MacOSX10.15.sdk/usr

PLATFORM_ARGS="
skia_use_x11=false \
target_os=\\"mac\\" 
skia_use_metal=false  
skia_use_fonthost_mac=true
skia_use_dng_sdk=false
skia_use_fontconfig=false
skia_use_freetype=false
"   
elif [[ "${target}" == *-apple-* ]]; then
PLATFORM_ARGS="
skia_use_x11=false \
target_os=\\"mac\\" 
skia_use_metal=true  
skia_enable_fontmgr_fontconfig=false
skia_use_fonthost_mac=true
"
elif [[ "${target}" == *-unknown-* ]]; then
PLATFORM_ARGS="
target_os=\\"FreeBSD\\" \
skia_use_dng_sdk=false
"
else
PLATFORM_ARGS="
skia_use_fontconfig=true \
"
fi

ARGS="
is_component_build=true \
target_cpu=\\"$target_cpu\\"
cc=\\"clang\\"
cxx=\\"clang++\\"
is_official_build=true
skia_enable_pdf=true
skia_enable_svg=true
skia_use_gl=true
skia_use_harfbuzz=false
skia_use_system_expat=true
skia_use_system_freetype2=false
skia_use_system_icu=true
skia_use_system_libjpeg_turbo=true
skia_use_system_libpng=true
skia_use_system_libwebp=true
skia_use_system_zlib=true
skia_use_lua=false
skia_use_piex=false
skia_use_dng_sdk=false
extra_cflags=[\\"-fpic\\", \\"-fvisibility=default\\"]
$PLATFORM_ARGS
"
bin/gn gen out/Dynamic --args="$ARGS"

ninja -j${nproc} -C out/Dynamic

cd out/Dynamic/


install -Dvm 755 "libskia.${dlext}" "${libdir}/libskia.${dlext}"
"""


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version= v"11.1.0", preferred_llvm_version = v"15.0.7", julia_compat="1.10")
