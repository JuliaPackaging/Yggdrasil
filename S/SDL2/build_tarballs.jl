# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2"
version = v"2.32.2"

# Collection of sources required to build SDL2
sources = [
    GitSource("https://github.com/libsdl-org/SDL.git",
              "e11183ea6caa3ae4895f4bc54cad2bbb0e365417"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL*/
mkdir build && cd build
FLAGS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(--with-x)
    if [[ "${target}" == *-freebsd* ]]; then
        # Needed for libusb_* symbols
        export LIBUSB_LIBS="-lusb"
    fi
elif [[ "${target}" == aarch64-apple-* ]]; then
    # Link to libclang_rt.osx to resolve the symbol `___isPlatformVersionAtLeast`:
    # <https://github.com/libsdl-org/SDL/issues/6491>.
    export LDFLAGS="-L${libdir}/darwin -lclang_rt.osx"
fi
../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared \
    --disable-static \
    "${FLAGS[@]}"
make -j${nproc} V=1
make install V=1
install_license ../LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2", "SDL2"], :libsdl2)
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# We must use the same version of LLVM for the build toolchain and LLVMCompilerRT_jll
llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcursor_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXScrnSaver_jll"; platforms=x11_platforms),
    Dependency("Libglvnd_jll"; platforms=x11_platforms),
    Dependency("alsa_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("alsa_plugins_jll"; platforms=filter(Sys.islinux, platforms)),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> Sys.isapple(p) && arch(p) == "aarch64", platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_llvm_version=llvm_version)
