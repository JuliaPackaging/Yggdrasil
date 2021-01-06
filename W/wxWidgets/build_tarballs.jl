using BinaryBuilder, Pkg

name = "wxWidgets"
version = v"3.1.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/wxWidgets/wxWidgets/releases/download/v$(version)/wxWidgets-$(version).tar.bz2",
                  "3ca3a19a14b407d0cdda507a7930c2e84ae1c8e74f946e0144d2fa7d881f1a94")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wxWidgets-*/
FLAGS=()
if [[ "${target}" == *-linux-musl ]]; then
    # Delete libexpat to prevent it from being picked up by mistake
    rm /usr/lib/libexpat.so*
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(ac_cv_search_libiconv_open=no)
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
cd docs
install_license preamble.txt licence.txt licendoc.txt gpl.txt lgpl.txt xserver.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("wxrc", :wxrc),
    #LibraryProduct("libwx_baseu", :libwx_baseu),
    #LibraryProduct("libwx_baseu", :libwx_baseu_net),
    #LibraryProduct("libwx_baseu_xml", :libwx_baseu_xml),
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
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6")),
    Dependency(PackageSpec(name="Libiconv_jll", uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531")),
    #Dependency(PackageSpec(name="SDL2_jll", uuid = "ab825dc5-c88e-5901-9575-1e5e20358fcf")),
    #Dependency(PackageSpec(name="Libtiff_jll", uuid = "89763e89-9b03-5906-acba-b20f662cd828")),
    #Dependency(PackageSpec(name="Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a")),
    #Dependency(PackageSpec(name="libpng_jll", uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f")),
    #Dependency(PackageSpec(name="JpegTurbo_jll", uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
