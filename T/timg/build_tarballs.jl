# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "timg"
version = v"1.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/hzeller/timg.git", "ce91140f560a58c2bf3e04a2c3374d6143000b4b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd timg/
echo "add_definitions(-D__STDC_FORMAT_MACROS)"|cat - CMakeLists.txt > tmp_out && mv tmp_out CMakeLists.txt 
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DWITH_VIDEO_DECODING=Off -DWITH_VIDEO_DEVICE=Off -DWITH_OPENSLIDE_SUPPORT=Off -DWITH_GRAPHICSMAGICK=Off -DTIMG_VERSION_FROM_GIT=Off
sed -i '$ s/$/ -lrt/' ./src/CMakeFiles/timg.dir/link.txt 
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("timg", :timg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="FFMPEG_jll", uuid="b22a6f82-2f65-5046-a5b2-351ab43fb4e5"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="libexif_jll", uuid="cdeeb48b-bcdf-5b3f-98c4-7a29487f695f"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
