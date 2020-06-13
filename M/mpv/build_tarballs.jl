# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mpv"
version = v"0.32.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mpv-player/mpv/archive/v0.32.0.tar.gz", "9163f64832226d22e24bbc4874ebd6ac02372cd717bef15c28a0aa858c5fe592")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mpv-*
ln -s /usr/bin/pkg-config /usr/bin/$target-pkg-config

# libstc++ required for c++ libs when using C compiler
if [[ "${nbits}" == 32 ]]; then
    export LDFLAGS="-L${prefix}/lib -liconv -Wl,-rpath-link,/opt/${target}/${target}/lib"
elif [[ "${target}" != *-apple-* ]]; then 
    export LDFLAGS="-L${prefix}/lib -liconv -Wl,-rpath-link,/opt/${target}/${target}/lib64"
else 
    export LDFLAGS="-L${prefix}/lib -liconv"
fi

# pkg-config files for ffmpeg are in $bindir for windows
if [[ "${target}" == *-mingw* ]]; then
    cp $bindir/pkgconfig/lib*  /workspace/destdir/lib/pkgconfig/
fi
python3 bootstrap.py

# No opengl on MacOS
if [[  "${target}" == *-apple-* ]]; then
    TARGET=$target ./waf --prefix=${prefix} --disable-manpage-build --enable-sdl2 --disable-gl configure
else 
    TARGET=$target ./waf --prefix=${prefix} --disable-manpage-build --enable-sdl2 configure
fi
./waf build -j${nproc}
./waf install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    ExecutableProduct("mpv", :mpv)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="FFMPEG_jll", uuid="b22a6f82-2f65-5046-a5b2-351ab43fb4e5"))
    Dependency(PackageSpec(name="Lua_jll", uuid="a4086b1d-a96a-5d6b-8e4f-2030e6f25ba6"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="Xorg_libXrandr_jll", uuid="ec84b674-ba8e-5d96-8ba1-2a689ba10484"))
    Dependency(PackageSpec(name="Xorg_libXinerama_jll", uuid="d1454406-59df-5ea1-beac-c340f2130bc3"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;preferred_gcc_version=v"7")
