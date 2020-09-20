# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL"
version = v"1.2.15"

# Collection of sources required to build SDL2
sources = [
    ArchiveSource("http://www.libsdl.org/release/SDL-$(version).tar.gz",
                  "d6d316a793e5e348155f0dd93b979798933fb98aa1edebcc108829d6474aad00"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/

git clone http://git.savannah.gnu.org/git/config.git/

cd SDL-*/
cp ../config/config* build-scripts/

FLAGS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
     FLAGS+=(--with-x);
fi

export CPPFLAGS="-I${prefix}/include"
export LDFLAGS="-L${libdir}"

# https://discourse.libsdl.org/t/install-error/21873/3
sed -i '/_XData32/d' src/video/x11/SDL_x11sym.h

# no LICENSE file
wget http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt
install_license lgpl-2.1.txt

./configure --prefix=${prefix} --host=${target} \
     --enable-shared \
     --disable-static \
     "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf)
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL"], :libsdl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"))
    Dependency(PackageSpec(name="Xorg_libXcursor_jll", uuid="935fb764-8cf2-53bf-bb30-45bb1f8bf724"))
    Dependency(PackageSpec(name="Xorg_libXext_jll", uuid="1082639a-0dae-5f34-9b06-72781eeb8cb3"))
    Dependency(PackageSpec(name="Xorg_libXinerama_jll", uuid="d1454406-59df-5ea1-beac-c340f2130bc3"))
    Dependency(PackageSpec(name="Xorg_libXrandr_jll", uuid="ec84b674-ba8e-5d96-8ba1-2a689ba10484"))
    Dependency(PackageSpec(name="Xorg_libXScrnSaver_jll", uuid="41e2f9bb-6422-5ff7-a427-aa949331d861"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
