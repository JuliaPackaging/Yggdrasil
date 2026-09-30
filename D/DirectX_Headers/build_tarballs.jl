using BinaryBuilder

name = "DirectX_Headers"
version = v"1.619.5"

sources = [
    GitSource("https://github.com/microsoft/DirectX-Headers.git",
              "ee479f0bd5f7b884f202bcf0c3f076cc050dd256"), # tag v1.619.5
]

script = raw"""
cd ${WORKSPACE}/srcdir/DirectX-Headers
meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --prefix=${prefix} \
    --buildtype=release \
    -D build-test=false
meson install -C build
install_license LICENSE
"""

platforms = supported_platforms()
# No d3d12 on macOS, and meson cannot detect the Apple linker for this project: its probe
# runs `clang -Wl,--version`, which ld64 rejects
filter!(!Sys.isapple, platforms)

# Headers plus a small static library of the COM GUIDs; nothing shared to dlopen. The
# pkg-config file is installed too, but it is not declared: meson puts it in
# libdata/pkgconfig on FreeBSD and lib/pkgconfig everywhere else.
products = [
    FileProduct("include/directx/d3d12.h", :d3d12_h),
    FileProduct("lib/libDirectX-Guids.a", :libDirectX_Guids),
]

dependencies = Dependency[]

# The non-Windows build compiles d3dx12_property_format_table.cpp, whose constexpr static
# member definition needs C++17
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
