using BinaryBuilder
import Pkg: PackageSpec

name = "Sokol"
version = v"2025.28.1"  # Use the commit date or tag of Sokol you're targeting

# Use the latest commit or a specific tag from the Sokol repository
sources = [
    GitSource("https://github.com/floooh/sokol.git", "db9ebdf24243572c190affde269b92725942ddd0"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz", 
               "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"),
    DirectorySource("./bundled"),
]

# Build script
script = raw"""
cd $WORKSPACE/srcdir/sokol*
export CFLAGS="-I${includedir}"
cp ${WORKSPACE}/srcdir/files/CMakeLists.txt ./CMakeLists.txt
cp ${WORKSPACE}/srcdir/files/sokol.c ./sokol.c

if [[ "${bb_full_target}" == x86_64-apple-darwin* ]]; then
    # LLVM 15+ requires macOS SDK 10.14.
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

if [[ ${target} == aarch64-apple-* ]]; then
    # `libclang_rt.osx.a` from LLVM compiler-rt.
    FLAGS+=(-DCMAKE_SHARED_LINKER_FLAGS="-L${libdir}/darwin -lclang_rt.osx"
            -DCMAKE_EXE_LINKER_FLAGS="-L${libdir}/darwin -lclang_rt.osx"
            -DUSE_METAL=ON
            )
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    "${FLAGS[@]}"

cmake --build build

install -Dvm 755 "build/libsokol.${dlext}" "${libdir}/libsokol.${dlext}"
for file in sokol_*.h; do
    install -Dvm 644 "${file}" -t "${includedir}"
done
install_license LICENSE
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
