include(joinpath("..", "common.jl"))

name = "Cairo"

# Dependencies that must be installed before this package can be built
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
    # Build with LZO errors on macOS:
    # /workspace/destdir/include/lzo/lzodefs.h:2197:1: error: 'lzo_cta__3' declared as an array with a negative size
    Dependency("LZO_jll"; compat="2.10.3", platforms=filter(!Sys.isapple, platforms)),
    Dependency("Zlib_jll"; compat="1.2.12"),
    # libcairo needs libssp on Windows, which is provided by CSL, but not in all versions of
    # Julia.  Note that above we're copying libssp to libdir for the versions of Julia where
    # this wasn't available.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
