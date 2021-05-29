using BinaryBuilder

name = "unpaper"
version = v"6.1.100" # <--- This version number is a lie, (it is v6.1) we just need to bump it to build for experimental platforms

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.flameeyes.com/files/unpaper-6.1.tar.xz",
                  "237c84f5da544b3f7709827f9f12c37c346cdf029b1128fb4633f9bafa5cb930"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/unpaper-*/
if [[ "${target}" == *-mingw* ]]; then
    # FFMPEG_jll installs the pkgconfig files in the wrong directory for Windows
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${libdir}/pkgconfig"
    # Give some hints to the linker
    export LDFLAGS="-L${libdir}"
    export LIBAV_LIBS="-lavformat -lavutil -lavcodec"
fi
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("unpaper", :unpaper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Offer a native xsltproc
    HostBuildDependency("XSLT_jll"),
    Dependency("FFMPEG_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# FFMPEG uses `preferred_gcc_version=v"8"`.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
