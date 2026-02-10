include(joinpath("..", "common.jl"))

name = "Cairo_nogpl"

# Ensure LZO is not present in the build environment — meson auto-detects it,
# so its mere presence would cause Cairo to link against GPL code.
script = raw"""
if [ -f "${includedir}/lzo/lzoconf.h" ]; then
    echo "ERROR: LZO found in build environment, but this is a nogpl build!" >&2
    exit 1
fi
""" * script

# Dependencies that must be installed before this package can be built
# This is the same as Cairo, but without LZO_jll (which is GPL-licensed).
# LZO is auto-detected by Cairo's meson build system; if absent, Cairo builds without it.
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_freebsd),
    Dependency("Glib_jll"; compat="2.84.0"),
    Dependency("Pixman_jll"; compat="0.44.2"),
    Dependency("libpng_jll"; compat="1.6.47"),
    Dependency("Fontconfig_jll"; compat="2.16.0"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Xorg_libXext_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXrender_jll"; platforms=linux_freebsd),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
