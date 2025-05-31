# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Skia"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [

    GitSource("https://github.com/google/skia.git", "482de011c920d85fdbe21a81c45852655df6a809"),
    GitSource("https://github.com/stensmo/cskia.git", "7dbb253909b533a8a3b6589e9c90a63e688b4910"),
    DirectorySource("./bundled")

]


# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms1 = [

     Platform("riscv64", "linux"; libc = "glibc"),

]

platforms2 = [

     Platform("x86_64", "linux"; libc = "glibc"),

]

platforms3 = [

     Platform("aarch64", "linux"; libc = "glibc"),

]


# The products that we will ensure are always built
products = [
    LibraryProduct("libskia", :libskia)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Fontconfig_jll", uuid="a3f928ae-7b40-5064-980b-68af3947d34b");)
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc");)
    Dependency(PackageSpec(name="xkbcommon_jll", uuid="d8fb68d0-12a3-5cfd-a85a-d49703b185fd"); )
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"); )
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b");)


]




# Bash recipe for building across all platforms
script1 = raw"""
cd $WORKSPACE/srcdir/
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd skia

install_license LICENSE 

bin/fetch-gn 
python3 tools/git-sync-deps || true

cp ../cskia/capi/sk_capi.cpp src/base/
cp ../cskia/capi/sk_capi.h src/base/

"""



script3= raw"""
ninja -j${nproc} -C out/Static

cd out/Static/

clang++ -shared -o libskia.so   -Wl,--whole-archive libskia.a -Wl,--no-whole-archive libfreetype2.a libjpeg.a libbentleyottmann.a libcompression_utils_portable.a libdng_sdk.a libjsonreader.a libpathkit.a  libpiex.a libpng.a libskcms.a libsksg.a libskshaper.a libskunicode_core.a libskunicode_icu.a libsvg.a -fpic -fvisibility=default -lstdc++ -dl -lfontconfig -lGL 

mkdir -p ${prefix}/lib/
cp libskia.so ${prefix}/lib/

"""





#Platform("riscv64", "linux"; libc = "glibc"), 


#target_cpu="arm64"

#target_cpu="riscv"

target_cpu="x64"
# Build the tarballs, and possibly a `build.jl` as well.



target_cpu="riscv"
script2= """
bin/gn gen out/Static --args='target_cpu="$(target_cpu)" cc="clang" cxx="clang++" is_official_build=true skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_vulkan=true skia_use_system_freetype2=false skia_use_fontconfig=true skia_enable_pdf=true  skia_use_system_icu=false skia_use_system_expat=false skia_use_harfbuzz=false skia_use_vulkan=true skia_use_gl=true extra_cflags=["-fpic", "-fvisibility=default"]'
"""
script = script1 * script2 * script3

# Disable for now, need to update fontconfig and OpenGL 
#build_tarballs(ARGS, name, version, sources, script, platforms1, products, dependencies; julia_compat="1.10", preferred_gcc_version = v"11.1.0", preferred_llvm_version = v"18.1.7")
target_cpu="x64"
script2= """
bin/gn gen out/Static --args='target_cpu="$(target_cpu)" cc="clang" cxx="clang++" is_official_build=true skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_vulkan=true skia_use_system_freetype2=false skia_use_fontconfig=true skia_enable_pdf=true  skia_use_system_icu=false skia_use_system_expat=false skia_use_harfbuzz=false skia_use_vulkan=true skia_use_gl=true extra_cflags=["-fpic", "-fvisibility=default"]'
"""
script = script1 * script2 * script3
build_tarballs(ARGS, name, version, sources, script, platforms2, products, dependencies; julia_compat="1.10", preferred_gcc_version = v"11.1.0", preferred_llvm_version = v"15.0.7")
target_cpu="arm64"
script2= """
bin/gn gen out/Static --args='target_cpu="$(target_cpu)" cc="clang" cxx="clang++" is_official_build=true skia_use_system_libjpeg_turbo=false skia_use_system_libpng=false skia_use_system_libwebp=false skia_use_system_zlib=false skia_use_vulkan=true skia_use_system_freetype2=false skia_use_fontconfig=true skia_enable_pdf=true  skia_use_system_icu=false skia_use_system_expat=false skia_use_harfbuzz=false skia_use_vulkan=true skia_use_gl=true extra_cflags=["-fpic", "-fvisibility=default"]'
"""
script = script1 * script2 * script3
#build_tarballs(ARGS, name, version, sources, script, platforms3, products, dependencies; julia_compat="1.10", preferred_gcc_version = v"11.1.0", preferred_llvm_version = v"15.0.7")









#target_os="mac"
#target_os="win"
#target_os="linux"
