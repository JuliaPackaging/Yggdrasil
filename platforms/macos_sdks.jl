# The natural way to handle installation of a new macOS SDK would be to
# add an ArchiveSource for the SDK and then moving it to the right place
# for the later build steps to find it.
#
# But this has the drawback of always extracting this (big) SDK, even on
# platforms that don't need it, which of course is most of them. Moreover,
# it floods the logs with the gargantuan list of files in these SDKs.
#
# Thus instead we use a FileSource. This way, the SDK is still always
# downloaded, but at least we can choose to only unpack it when we really
# need it. Plus we can directly unpack it in its final location; and
# suppress the full list of files being unpackaged
const macos_sdk_sources = Dict{String,FileSource}(
    # this is the default SDK we use, so there is normally no need to request this;
    # but we include it here to make this function also usable in the rootfs
    "10.12" =>
        FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.12.sdk.tar.xz",
                   "6852728af94399193599a55d00ae9c4a900925b6431534a3816496b354926774"),
    "10.13" =>
        FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.13.sdk.tar.xz",
                   "a3a077385205039a7c6f9e2c98ecdf2a720b2a819da715e03e0630c75782c1e4"),
    "10.14" =>
        FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                   "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"),
    "10.15" =>
        FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                   "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    "11.0" =>
        FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.0-11.1/MacOSX11.0.sdk.tar.xz",
                   "c8a9ff16196be43c35b699dd293f0c0563f1239c99caa6b3d53882e556a209bd"),
    "11.1" =>
        FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.0-11.1/MacOSX11.1.sdk.tar.xz",
                   "9b86eab03176c56bb526de30daa50fa819937c54b280364784ce431885341bf6"),
    "11.3" =>
        FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz",
                   "cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4"),
    "12.3" =>
        FileSource("https://github.com/realjf/MacOSX-SDKs/releases/download/v0.0.1/MacOSX12.3.sdk.tar.xz",
                   "a511c1cf1ebfe6fe3b8ec005374b9c05e89ac28b3d4eb468873f59800c02b030"),
    "14.0" =>
        FileSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                   "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    "14.5" =>
        FileSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.5/MacOSX14.5.sdk.tar.xz",
                   "d2b7784a8b63cfcc686059aef6f1065dc8d2aaeddc39245738f4c0cd9ca6165a"),
    "15.0" =>
        FileSource("https://github.com/joseluisq/MacOSX-SDKs/releases/download/15.0/MacOSX15.0.sdk.tar.xz",
                   "9df0293776fdc8a2060281faef929bf2fe1874c1f9368993e7a4ef87b1207f98"),
)

"""
    require_macos_sdk(version::String, sources::Vector, script::String;
                      deployment_target::String = version)

Augment `sources` and `script` to ensure the macOS SDK with the indicated
`version` is available when building for macOS. Returns a new `sources` and
script value.

Currently this only has an effect when building for macOS on Intel hardware,
as the ARM builder already uses a recent SDK. In the future this may also gain
support for installing newer SDK versions on ARM as well.
"""
function require_macos_sdk(version::String, sources::Vector, script::String; deployment_target::String = version)
    return vcat(sources, get_macos_sdk_sources(version)),
           get_macos_sdk_script(version; deployment_target) * script
end

"""
    get_macos_sdk_sources(version::String)

Return a vector of sources to be appended to the `sources` list of a build recipe,
and `sdk_script` is a string to be inserted (usually at the start) of
the build script.

If used together with `get_macos_sdk_script` this ensures that the macOS SDK
with the indicated `version` is available when building for macOS.

Normally using `require_macos_sdk` should be preferred over this, so that the
SDK version is specified in a single place. But when necessary it is useful to
have this low-level alternative.
"""
function get_macos_sdk_sources(version::String)
    haskey(macos_sdk_sources, version) || error("unsupported macOS SDK version $version")

    # return a vector just in case in the future we might need more than one source
    return [ macos_sdk_sources[version] ]
end

"""
    get_macos_sdk_script(version::String)

Return a a string to be inserted (usually at the start) of the build script
of a build recipe.

If used together with `get_macos_sdk_sources` this ensures that the macOS SDK
with the indicated `version` is available when building for macOS.

Normally using `require_macos_sdk` should be preferred over this, so that the
SDK version is specified in a single place. But when necessary it is useful to
have this low-level alternative.
"""
function get_macos_sdk_script(version::String; deployment_target::String = version)
    # on ARM, the default macOS SDK we use is 11.1; so if the requested SDK
    # version is older or equal to that, we can restrict to intel
    arch = VersionNumber(version) <= v"11.1" ? "x86_64" : "*"
    return """
        macos_sdk_version=$version
        macosx_deployment_target=$deployment_target
        """ *
    raw"""
    if [[ "${target}" == """*arch*raw"""-apple-darwin* ]]; then
        echo "Extracting MacOSX${macos_sdk_version}.sdk.tar.xz (this may take a while)"
        rm -rf /opt/${target}/${target}/sys-root/System
        rm -rf /opt/${target}/${target}/sys-root/usr/include/libxml2/libxml
        # extract the tarball into the sys-root so all compilers pick it up
        # automatically, and use --warning=no-unknown-keyword to hide harmless
        # warnings about unsupported pax header keywords like "SCHILY.fflags"
        tar --extract \
            --file=${WORKSPACE}/srcdir/MacOSX${macos_sdk_version}.sdk.tar.xz \
            --directory="/opt/${target}/${target}/sys-root/." \
            --strip-components=1 \
            --warning=no-unknown-keyword \
            MacOSX${macos_sdk_version}.sdk/System \
            MacOSX${macos_sdk_version}.sdk/usr
        export MACOSX_DEPLOYMENT_TARGET=${macosx_deployment_target}
    fi
    """
end
