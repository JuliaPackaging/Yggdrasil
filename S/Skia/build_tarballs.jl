# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Skia"
version = v"0.40.0"

# Collection of sources required to complete build
sources = [
   GitSource("https://github.com/google/skia.git", "482de011c920d85fdbe21a81c45852655df6a809"),
   GitSource("https://github.com/stensmo/cskia.git", "3438e6efd3a4f27f43457db675ceb33da30c60cf"),
   DirectorySource("./bundled"),
   GitSource("https://chromium.googlesource.com/chromium/src/buildtools.git","1760ff6d7267dd97ae1968c7bee9ce04a2a8489d"),
   GitSource("https://android.googlesource.com/platform/external/dng_sdk.git","dbe0a676450d9b8c71bf00688bb306409b779e90"),
   GitSource("https://chromium.googlesource.com/external/github.com/libexpat/libexpat.git","624da0f593bb8d7e146b9f42b06d8e6c80d032a3"),
   GitSource("https://chromium.googlesource.com/chromium/src/third_party/freetype2.git","5d4e649f740c675426fbe4cdaffc53ee2a4cb954"),
   GitSource("https://chromium.googlesource.com/external/github.com/harfbuzz/harfbuzz.git","ca3cd48fa3e06fa81d7c8a3f716cca44ed2de26a"),
   GitSource("https://chromium.googlesource.com/chromium/deps/icu.git","364118a1d9da24bb5b770ac3d762ac144d6da5a4"),
   GitSource("https://chromium.googlesource.com/codecs/libgav1.git","5cf722e659014ebaf2f573a6dd935116d36eadf1"),
   GitSource("https://chromium.googlesource.com/chromium/deps/libjpeg_turbo.git","e14cbfaa85529d47f9f55b0f104a579c1061f9ad"),
   GitSource("https://chromium.googlesource.com/external/gitlab.com/wg1/jpeg-xl.git","a205468bc5d3a353fb15dae2398a101dff52f2d3"),
   GitSource("https://skia.googlesource.com/third_party/libpng.git","ed217e3e601d8e462f7fd1e04bed43ac42212429"),
   GitSource("https://chromium.googlesource.com/webm/libwebp.git","845d5476a866141ba35ac133f856fa62f0b7445f"),
   GitSource("https://chromium.googlesource.com/libyuv/libyuv.git","d248929c059ff7629a85333699717d7a677d8d96"),
   GitSource("https://android.googlesource.com/platform/external/piex.git","bb217acdca1cc0c16b704669dd6f91a1b509c406"),
   GitSource("https://chromium.googlesource.com/external/github.com/unicode-org/unicodetools","66a3fa9dbdca3b67053a483d130564eabc5fe095"),
   GitSource("https://skia.googlesource.com/external/github.com/google/wuffs-mirror-release-c.git","e3f919ccfe3ef542cfc983a82146070258fb57f8"),
   GitSource("https://chromium.googlesource.com/chromium/src/third_party/zlib","646b7f569718921d7d4b5b8e22572ff6c76f2596"),

]




# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> Sys.islinux(p) || (Sys.isapple(p) && arch(p) == "aarch64"), platforms)




# The products that we will ensure are always built
products = [
    LibraryProduct("libskia", :libskia)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Fontconfig_jll"; compat="2.16.0")
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
mv libexpat expat
mv libjpeg_turbo libjpeg-turbo

# Move dependencies to the correct location
mv !(cskia|buildtools|skia|patches) skia/third_party/externals/

mv buildtools/ skia/


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




if [[ "${target}" == aarch64-apple-* ]]; then
PLATFORM_ARGS="
skia_use_x11=false \
target_os=\\"mac\\" 
skia_use_metal=true  
skia_enable_fontmgr_fontconfig=false
skia_use_fonthost_mac=true
"
else
PLATFORM_ARGS="
skia_use_fontconfig=true \
skia_use_vulkan=false
"
fi

ARGS="
is_component_build=true \
target_cpu=\\"$target_cpu\\"
cc=\\"clang\\"
cxx=\\"clang++\\"
is_official_build=true
skia_enable_pdf=true
skia_use_gl=true
skia_use_harfbuzz=false
skia_use_dng_sdk=true
skia_use_system_expat=false
skia_use_system_freetype2=false
skia_use_system_icu=false
skia_use_system_libjpeg_turbo=false
skia_use_system_libpng=false
skia_use_system_libwebp=false
extra_cflags=[\\"-fpic\\", \\"-fvisibility=default\\"]
$PLATFORM_ARGS
"
bin/gn gen out/Dynamic --args="$ARGS"

ninja -j${nproc} -C out/Dynamic

cd out/Dynamic/


install -Dvm 755 "libskia.${dlext}" "${libdir}/libskia.${dlext}"
"""


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version= v"11.1.0", preferred_llvm_version = v"15.0.7", julia_compat="1.10")
