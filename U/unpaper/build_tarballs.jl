using BinaryBuilder

name = "unpaper"
version = v"7.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/unpaper/unpaper.git",
                  "5211a623d48858eae154213a61bccbc368b19ca0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/unpaper*/
if [[ "${target}" == *-mingw* ]]; then
    # FFMPEG_jll installs the pkgconfig files in the wrong directory for Windows
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${libdir}/pkgconfig"
    # Give some hints to the linker
    export LDFLAGS="-L${libdir}"
    export LIBAV_LIBS="-lavformat -lavutil -lavcodec"
fi
mkdir build && cd build
meson setup --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

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
