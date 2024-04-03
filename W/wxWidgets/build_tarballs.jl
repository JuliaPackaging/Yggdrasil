# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wxWidgets"
version = v"3.2.4"

version_mm = "$(version.major).$(version.minor)"
version_no_sep = "$(version.major)$(version.minor)"

gen_libnames(lib) = ["libwx_gtk3u_$(lib)-$(version_mm)",
                    "wxmsw$(version_no_sep)u_$(lib)_gcc_custom",
                    "libwx_osx_cocoau_$(lib)-$(version_mm)-x86_64-apple-darwin14",
                    "libwx_osx_cocoau_$(lib)-$(version_mm)-aarch64-apple-darwin20"]

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/wxWidgets/wxWidgets/releases/download/v$version/wxWidgets-$version.tar.bz2", "0640e1ab716db5af2ecb7389dbef6138d7679261fbff730d23845ba838ca133e"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/wxWidgets-*

if [[ "${target}" == *-linux-musl* ]]; then

    #help find zlib for some reason
    export CPPFLAGS="-I${includedir}"

    # Delete libexpat to prevent it from being picked up by mistake
    rm /usr/lib/libexpat.so*

elif [[ "${target}" == *-freebsd* ]]; then

    #help find libpng for some reason
    export CPPFLAGS="-I${includedir}"

elif [[ "${target}" == *-darwin* ]]; then

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

# Override insane script which tries to code sign **all** libraries in
# ${libdir}, seriously??
echo > change-install-names

make -j${nproc}
make install

install_license docs/preamble.txt docs/licence.txt docs/licendoc.txt docs/gpl.txt docs/lgpl.txt docs/xserver.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental = true))
filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
#[linux_naming_scheme, mingw_naming_scheme, macos_naming_scheme]
#see https://github.com/wxWidgets/wxWidgets/blob/master/docs/contributing/about-platform-toolkit-and-library-names.md for more info on naming
products = [
    ExecutableProduct("wxrc-$(version_mm)", :wxrc),
    LibraryProduct(["libwx_baseu-$(version_mm)","wxbase$(version_no_sep)u_gcc_custom", "libwx_baseu-$(version_mm)-x86_64-apple-darwin14", "libwx_baseu-$(version_mm)-aarch64-apple-darwin20"], :baseu),
    LibraryProduct(["libwx_baseu_net-$(version_mm)","wxbase$(version_no_sep)u_net_gcc_custom", "libwx_baseu_net-$(version_mm)-x86_64-apple-darwin14", "libwx_baseu_net-$(version_mm)-aarch64-apple-darwin20"], :baseu_net),
    LibraryProduct(["libwx_baseu_xml-$(version_mm)","wxbase$(version_no_sep)u_xml_gcc_custom", "libwx_baseu_xml-$(version_mm)-x86_64-apple-darwin14", "libwx_baseu_xml-$(version_mm)-aarch64-apple-darwin20"], :baseu_xml),
    LibraryProduct(gen_libnames("aui"), :aui),
    #LibraryProduct(gen_libnames("adv"), :adv),
    LibraryProduct(gen_libnames("core"), :core),
    LibraryProduct(gen_libnames("html"), :html),
    LibraryProduct(gen_libnames("propgrid"), :propgrid),
    LibraryProduct(gen_libnames("qa"), :qa),
    LibraryProduct(gen_libnames("ribbon"), :ribbon),
    LibraryProduct(gen_libnames("richtext"), :richtext),
    LibraryProduct(gen_libnames("stc"), :stc),
    LibraryProduct(gen_libnames("xrc"), :xrc)
    
]


# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"); compat="7.73,8")
    Dependency(PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6"))
    Dependency(PackageSpec(name="Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
    Dependency("Expat_jll"; compat="2.2.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
# wxMSW fails on gcc4 and 5, wxGTK works on everything
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6",preferred_gcc_version=v"6")
