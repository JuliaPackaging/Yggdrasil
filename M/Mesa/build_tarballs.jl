# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mesa"
version = v"26.0.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://archive.mesa3d.org/mesa-$version.tar.xz",
                  "ddb7443d328e89aa45b4b6b80f077bf937f099daeca8ba48cabe32aab769e134"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mesa-*

apk add py3-mako py3-yaml py3-packaging

MESA_FLAGS=(
    -D b_ndebug=true
    -D buildtype=release
    -D strip=true
    -D llvm=disabled
    -D gallium-drivers=softpipe
    -D vulkan-drivers=[]
    -D gles1=disabled
    -D gles2=disabled
    -D shader-cache=disabled
)

if [[ "${target}" == *-mingw* ]]; then
    MESA_FLAGS+=(
        -D platforms=windows
        -D glx=disabled
        -D egl=disabled
        -D gbm=disabled
    )
elif [[ "${target}" == *-linux* ]] || [[ "${target}" == *-freebsd* ]]; then
    MESA_FLAGS+=(
        -D platforms=x11
        -D glx=xlib
        -D egl=disabled
        -D gbm=disabled
    )
fi

meson setup build "${MESA_FLAGS[@]}" --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -C build -j${nproc}
ninja -C build install

if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/bin/opengl32.dll ${prefix}/bin/opengl32sw.dll
fi

install_license docs/license.rst
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# macOS provides OpenGL natively; Mesa doesn't produce a GL library without X11/GLX
filter!(p -> !Sys.isapple(p), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["opengl32sw", "libGL"], :libmesaGL),
]

# Dependencies that must be installed before this package can be built
x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Expat_jll"; platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libxcb_jll"; platforms=x11_platforms),
    Dependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Xorg_libxshmfence_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXxf86vm_jll"; platforms=x11_platforms),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10", clang_use_lld=false)
