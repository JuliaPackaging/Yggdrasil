# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GLEW"
version = v"2.2.0"

# Collection of sources required to build GLEW
sources = [
    ArchiveSource("https://github.com/nigels-com/glew/releases/download/glew-$(version)/glew-$(version).tgz",
                  "d4fc82893cfb00109578d0a1a2337fb8ca335b3ceccf97b97e5cc7f08e4353e1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glew-*
EXTRA_VARS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    # On Linux and FreeBSD this variable by default does `-L/usr/lib`
    EXTRA_VARS+=(LDFLAGS.EXTRA="")
elif [[ "${target}" == *-mingw* ]]; then
    # On MinGW targets this is incorrectly detected as "msys"
    EXTRA_VARS+=(SYSTEM="mingw")
fi

make INCLUDE="-Iinclude -I${includedir}" \
    GLEW_DEST="${prefix}" \
    "${EXTRA_VARS[@]}" \
    install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libGLEW", "glew32"], :libGLEW),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libXi_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
