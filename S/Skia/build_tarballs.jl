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
]


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> Sys.islinux(p) && libc(p) == "glibc" && arch(p) ∉ ("armv6l", "armv7l"), platforms)



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

echo $target

cd $WORKSPACE/srcdir/
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd skia

install_license LICENSE 

bin/fetch-gn 

# The || true is necessary, since the script fails for some Android deps. || true should be removed for future versions
python3 tools/git-sync-deps || true

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
fi

ARGS="
is_component_build=true \
target_cpu=\\"$target_cpu\\"
cc=\\"clang\\"
cxx=\\"clang++\\"
is_official_build=true
skia_enable_pdf=true
skia_use_fontconfig=true
skia_use_gl=true
skia_use_harfbuzz=false
skia_use_system_expat=false
skia_use_system_freetype2=false
skia_use_system_icu=false
skia_use_system_libjpeg_turbo=false
skia_use_system_libpng=false
skia_use_system_libwebp=false
skia_use_system_zlib=false
skia_use_vulkan=true
extra_cflags=[\\"-fpic\\", \\"-fvisibility=default\\"]
"
bin/gn gen out/Dynamic --args="$ARGS"

ninja -j${nproc} -C out/Dynamic

cd out/Dynamic/

# Checks that one of the required symbols for the Julia API are included in libskia.so. 
nm -D libskia.so | grep -q "sk_string_new_empty" && true || false

install -Dvm 755 "libskia.${dlext}" "${libdir}/libskia.${dlext}"
"""


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version= v"11.1.0", preferred_llvm_version = v"15.0.7", julia_compat="1.10")
