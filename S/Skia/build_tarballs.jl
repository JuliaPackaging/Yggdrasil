# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Skia"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [

   GitSource("https://github.com/google/skia.git", "482de011c920d85fdbe21a81c45852655df6a809"),
   GitSource("https://github.com/stensmo/cskia.git", "500cdca61e2105555f339fa363f55e30696b009f"),
   DirectorySource("./bundled")

]


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line


platforms = [
     Platform("x86_64", "linux"; libc = "glibc"),
     Platform("aarch64", "linux"; libc = "glibc"),
     Platform("riscv64", "linux"; libc = "glibc"), 
     Platform("powerpc64le", "linux"; libc = "glibc"), 
     Platform("i686", "linux"; libc = "glibc"),
]




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

# The || true is necessary, since the script fails for some Android deps
python3 tools/git-sync-deps || true

cp ../cskia/capi/sk_capi.cpp src/base/
cp ../cskia/capi/sk_capi.h src/base/


if [[ "${target}" == x86_64-* ]]; then
    target_cpu=x64
elif [[ "${target}" == aarch64-* ]]; then
    target_cpu=arm64
elif [[ "${target}" == riscv64-* ]]; then
    target_cpu=riscv
fi

if [[ "${target}" == powerpc64le-* ]]; then
    target_cpu=powerpc64le
fi

if [[ "${target}" == i686-* ]]; then
    target_cpu=x86
fi



bin/gn gen out/Static --args='target_cpu="'$target_cpu'" cc="clang" cxx="clang++" is_official_build=true skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_vulkan=true skia_use_system_freetype2=false skia_use_fontconfig=true skia_enable_pdf=true  skia_use_system_icu=false skia_use_system_expat=false skia_use_harfbuzz=false skia_use_vulkan=true skia_use_gl=true extra_cflags=["-fpic", "-fvisibility=default"]'


ninja -j${nproc} -C out/Static

cd out/Static/


clang++ -shared -o libskia.${dlext} $(flagon -Wl,--whole-archive) libskia.a $(flagon -Wl,--no-whole-archive) libfreetype2.a libjpeg.a libbentleyottmann.a libcompression_utils_portable.a libdng_sdk.a libjsonreader.a libpathkit.a  libpiex.a libpng.a libskcms.a libsksg.a libskshaper.a libskunicode_core.a libskunicode_icu.a libsvg.a -fpic -dl -lfontconfig -lGL


install -Dvm 755 "libskia.${dlext}" "${libdir}/libskia.${dlext}"
"""


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_gcc_version = v"11.1.0", preferred_llvm_version = v"15.0.7")
