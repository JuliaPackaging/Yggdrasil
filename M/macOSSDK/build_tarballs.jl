using BinaryBuilder2

name = "macOSSDK"
version = v"11.1"

# The unmodified Apple macOS SDK; this is the macOS sysroot that BinaryBuilder2's
# toolchains build against.
sources = [
    ArchiveSource("https://github.com/joseluisq/macosx-sdks/releases/download/$(version.major).$(version.minor)/MacOSX$(version.major).$(version.minor).sdk.tar.xz",
                  "97a916b0b68aae9dcd32b7d12422ede3e5f34db8e169fa63bfb18ec410b8f5d9"),
    DirectorySource("./bundled"),
]

script = raw"""
mv -v MacOSX*.sdk/usr ${prefix}/usr
mv -v MacOSX*.sdk/System ${prefix}/
install_license LICENSE.md
rm -rf ${prefix}/usr/share/man
"""

platforms = filter(Sys.isapple, supported_platforms())

products = [
    FileProduct("usr/include/Availability.h", :Availability_h),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    host_toolchains = [HostToolsToolchain()],
    target_toolchains = [],
)
