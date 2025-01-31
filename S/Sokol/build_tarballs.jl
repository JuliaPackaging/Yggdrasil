using BinaryBuilder
import Pkg: PackageSpec
include("create_sokol_c.jl")
include("create_cmakelists.jl")

name = "Sokol"
version = v"2025.28.1"  # Use the commit date or tag of Sokol you're targeting

# Use the latest commit or a specific tag from the Sokol repository
sources = [
    GitSource("https://github.com/floooh/sokol.git", "db9ebdf24243572c190affde269b92725942ddd0"),  # Replace with actual commit
]

# Build script
script = raw"""
cd $WORKSPACE/srcdir/sokol*
export CFLAGS="-I${includedir}"
$(create_sokol_c)
$(create_cmakelists)
if [[ ${target} == aarch64-apple-* ]]; then
    # Linking FFMPEG requires the function `__divdc3`, which is implemented in
    # `libclang_rt.osx.a` from LLVM compiler-rt.
    FLAGS+=(-DCMAKE_SHARED_LINKER_FLAGS="-L${libdir}/darwin -lclang_rt.osx"
            -DCMAKE_EXE_LINKER_FLAGS="-L${libdir}/darwin -lclang_rt.osx"
            )
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    "${FLAGS[@]}"

cmake --build build

install -Dm 755 "build/libsokol.${dlext}" "${libdir}/libsokol.${dlext}"
install -Dm 755 "sokol_gfx.h" "${includedir}/sokol_gfx.h"
install -Dm 755 "sokol_app.h" "${includedir}/sokol_app.h"
install -Dm 755 "sokol_audio.h" "${includedir}/sokol_audio.h"
install -Dm 755 "sokol_time.h" "${includedir}/sokol_time.h"
install -Dm 755 "sokol_glue.h" "${includedir}/sokol_glue.h"
install -Dm 755 "sokol_log.h" "${includedir}/sokol_log.h"
install -Dm 755 "sokol_args.h" "${includedir}/sokol_args.h"
install -Dm 755 "sokol_fetch.h" "${includedir}/sokol_fetch.h"
"""

# Supported platforms
platforms = supported_platforms(exclude=p->arch(p)=="armv6l"||Sys.isfreebsd(p)||arch(p)=="riscv64")
llvm_version = v"13.0.1+1"

# Platform-specific dependencies
dependencies = [
    # Linux dependencies
    Dependency("Xorg_libX11_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Xorg_libXrandr_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Xorg_libXi_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Xorg_libXcursor_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Xorg_libXinerama_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Libglvnd_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("alsa_jll"; platforms=filter(Sys.islinux, platforms)),
    BuildDependency("Xorg_xorgproto_jll"; platforms=filter(Sys.islinux, platforms)),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
    platforms=[Platform("aarch64", "macos")])
]

# Library products
products = [
    LibraryProduct("libsokol", :libsokol)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7", preferred_llvm_version=llvm_version)
