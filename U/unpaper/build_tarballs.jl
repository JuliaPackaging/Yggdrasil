using BinaryBuilder

name = "unpaper"
version = v"6.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.flameeyes.com/files/unpaper-6.1.tar.xz",
                  "237c84f5da544b3f7709827f9f12c37c346cdf029b1128fb4633f9bafa5cb930"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/unpaper-6.1/
apk add libxslt
if [[ "${target}" == *-linux-* ]]; then
    export LDFLAGS="-lstdc++"
fi
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("unpaper", :unpaper),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("FFMPEG_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# FFMPEG uses `preferred_gcc_version=v"8"`.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
