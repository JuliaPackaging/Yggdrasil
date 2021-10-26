# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wxWidgets"
version = v"3.1.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/wxWidgets/wxWidgets/archive/refs/tags/v$version.tar.gz", "e8fd5f9fbff864562aa4d9c094f898c97f5e1274c90f25beb0bfd5cb61319dea"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/wxWidgets-*

if [[ "${target}" == *-linux-musl* ]]; then

    #derived from https://github.com/wxWidgets/wxWidgets/commit/f4eae4df2a256d0c1bab1657438c2de449cdcd67?branch=f4eae4df2a256d0c1bab1657438c2de449cdcd67&diff=split
    #this was merged on master, so probably can get rid of next release
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/musl-add-locale-functions.patch
    
    #help find zlib for some reason
    export CPPFLAGS="-I${includedir}"

    # Delete libexpat to prevent it from being picked up by mistake
    rm /usr/lib/libexpat.so*

elif [[ "${target}" == *-freebsd* ]]; then

    #help find libpng for some reason
    export CPPFLAGS="-I${includedir}"

elif [[ "${target}" == *-apple* ]]; then

    #see https://trac.wxwidgets.org/ticket/19159 for issue tracker and https://github.com/wxWidgets/wxWidgets/pull/2354 for source of patch
    #this has since been merged into master, unsure about future status?
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/apple-add-bridging-commit.patch
    
    #fix missing symbols error - Undefined symbols for architecture x86_64: "___isPlatformVersionAtLeast". I think something to do with cross-compiling and we don't have access to XCode libraries??
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/osx-disable-builtin-platform-check.patch

fi

CONFIGURE_FLAGS=(--prefix=${prefix}
                --build=${MACHTYPE}
                --host=${target}
                --includedir=${includedir}
                --libdir=${libdir}
                --with-libiconv=ON
                --with-libcurl=ON
                --with-libpng=sys
                --with-libjpeg=sys
                --with-libtiff=sys
                --with-zlib=sys
                --with-expat=sys
                --disable-tests
                )

#wxWidgets has a couple of variants available (see "Supported Platforms" section https://www.wxwidgets.org/about/). 
#On Unix platforms, we'll build the wxGTK variant, on MinGW platforms we'll build the wxMSW variant, and we'll build the OSX/OSCocoa variant on mac platforms.

if [[ "${target}" == *-apple* ]]; then
    CONFIGURE_FLAGS+=(--with-osx_cocoa)
    CONFIGURE_FLAGS+=(--with-macosx-version-min=10.12)
elif [[ "${target}" == *-mingw* ]]; then
    CONFIGURE_FLAGS+=(--with-msw)
else
    CONFIGURE_FLAGS+=(--with-gtk=3)
fi

./configure ${CONFIGURE_FLAGS[@]}

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
#[linux_naming_scheme, mingw_naming_scheme, macos_naming_scheme]
#see https://github.com/wxWidgets/wxWidgets/blob/master/docs/contributing/about-platform-toolkit-and-library-names.md for more info on naming
products = [
    ExecutableProduct("wxrc-$(version.major).$(version.minor)", :wxrc),
    #LibraryProduct(["libwx_gtk3u_adv-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_adv_gcc_custom", "libwx_osx_cocoau_adv-$(version.major).$(version.minor).$(version.patch)"], :adv),
    LibraryProduct(["libwx_gtk3u_core-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_core_gcc_custom", "libwx_osx_cocoau_core-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :core),
    LibraryProduct(["libwx_gtk3u_richtext-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_richtext_gcc_custom", "libwx_osx_cocoau_richtext-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :richtext),
    LibraryProduct(["libwx_gtk3u_html-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_html_gcc_custom", "libwx_osx_cocoau_html-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :html),
    LibraryProduct(["libwx_baseu_xml-$(version.major).$(version.minor)","wxbase$(version.major)$(version.minor)$(version.patch)u_xml_gcc_custom", "libwx_baseu_xml-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :baseu_xml),
    LibraryProduct(["libwx_gtk3u_aui-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_aui_gcc_custom", "libwx_osx_cocoau_aui-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :aui),
    LibraryProduct(["libwx_gtk3u_stc-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_stc_gcc_custom", "libwx_osx_cocoau_stc-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :stc),
    LibraryProduct(["libwx_baseu-$(version.major).$(version.minor)","wxbase$(version.major)$(version.minor)$(version.patch)u_gcc_custom", "libwx_baseu-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :baseu),
    LibraryProduct(["libwx_gtk3u_qa-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_qa_gcc_custom", "libwx_osx_cocoau_qa-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :qa),
    LibraryProduct(["libwx_gtk3u_ribbon-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_ribbon_gcc_custom", "libwx_osx_cocoau_ribbon-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :ribbon),
    LibraryProduct(["libwx_gtk3u_propgrid-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_propgrid_gcc_custom", "libwx_osx_cocoau_propgrid-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :propgrid),
    LibraryProduct(["libwx_gtk3u_xrc-$(version.major).$(version.minor)","wxmsw$(version.major)$(version.minor)$(version.patch)u_xrc_gcc_custom", "libwx_osx_cocoau_xrc-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :xrc),
    LibraryProduct(["libwx_baseu_net-$(version.major).$(version.minor)","wxbase$(version.major)$(version.minor)$(version.patch)u_net_gcc_custom", "libwx_baseu_net-$(version.major).$(version.minor)-x86_64-apple-darwin14"], :baseu_net)
]


# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"))
    Dependency(PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6"))
    Dependency(PackageSpec(name="Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
    Dependency("Expat_jll"; compat="2.2.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
#wxMSW fails on gcc4 and 5, wxGTK works on everything
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6",preferred_gcc_version=v"6")
