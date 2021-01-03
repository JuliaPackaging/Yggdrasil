using BinaryBuilder, Pkg

name = "WxWidgets"
version = v"3.1.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/wxWidgets/wxWidgets/releases/download/v$(version)/wxWidgets-$(version).tar.bz2",
                  "3ca3a19a14b407d0cdda507a7930c2e84ae1c8e74f946e0144d2fa7d881f1a94")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wxWidgets-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("wxrc-3", :wxrc),
    LibraryProduct("libwx_baseu-3", :libwx_baseu),
    LibraryProduct("libwx_baseu_net-3", :libwx_baseu_net),
    LibraryProduct("libwx_baseu_xml-3", :libwx_baseu_xml),
    #LibraryProduct("libwx_gtk3u_adv-$(version.major)", :libwx_gtk3u_adv),
    #LibraryProduct("libwx_gtk3u_aui-$(version.major)", :libwx_gtk3u_aui),
    #LibraryProduct("libwx_gtk3u_core-$(version.major)", :libwx_gtk3u_core),
    #LibraryProduct("libwx_gtk3u_html-$(version.major)", :libwx_gtk3u_html),
    #LibraryProduct("libwx_gtk3u_propgrid-$(version.major)", :libwx_gtk3u_propgrid),
    #LibraryProduct("libwx_gtk3u_qa-$(version.major)", :libwx_gtk3u_qa),
    #LibraryProduct("libwx_gtk3u_ribbon-$(version.major)", :libwx_gtk3u_ribbon),
    #LibraryProduct("libwx_gtk3u_richtext-$(version.major)", :libwx_gtk3u_richtext),
    #LibraryProduct("libwx_gtk3u_stc-$(version.major)", :libwx_gtk3u_stc),
    #LibraryProduct("libwx_gtk3u_xrc-$(version.major)", :libwx_gtk3u_xrc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6")),
    Dependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
