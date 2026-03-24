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

# Use llvmpipe where LLVM is available, fall back to softpipe
if [ -f "${prefix}/tools/llvm-config" ]; then
    GALLIUM_DRIVERS="softpipe,llvmpipe"
    LLVM_FLAG="-D llvm=enabled -D shared-llvm=disabled -D cpp_rtti=false"
    # Our LLVM was built with Intel JIT events enabled in headers but without the library
    sed -i 's/LLVM_USE_INTEL_JITEVENTS/LLVM_USE_INTEL_JITEVENTS_DISABLED/' src/gallium/auxiliary/gallivm/lp_bld_misc.cpp
    # Tell meson where to find llvm-config for cross compilation
    sed -i "/^\[binaries\]/a llvm-config = '${prefix}/tools/llvm-config'" ${MESON_TARGET_TOOLCHAIN}
else
    GALLIUM_DRIVERS="softpipe"
    LLVM_FLAG="-D llvm=disabled"
fi

MESA_FLAGS=(
    -D b_ndebug=true
    -D buildtype=release
    -D strip=true
    ${LLVM_FLAG}
    -D gallium-drivers=${GALLIUM_DRIVERS}
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
# LLVM links C++ symbols into Mesa, requiring cxxstring ABI expansion
platforms = expand_cxxstring_abis(platforms)

# Platforms where LLVM_full_jll is available (all except i686-linux-musl)
llvm_platforms = filter(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)

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
    # LLVM for llvmpipe (statically linked into Mesa, no runtime dep needed)
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"18.1.7+5"); platforms=llvm_platforms),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10", clang_use_lld=false)
