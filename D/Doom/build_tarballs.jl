
using BinaryBuilder, Pkg

name = "Doom"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AlexOberhofer/sdl2-doom.git",
              "da7732ee6318371db2ee04ec4702c6064245846b"),
    DirectorySource("bundled"),
    FileSource("https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad",
               "1d7d43be501e67d927e415e0b8f3e29c3bf33075e859721816f652a526cac771"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/sdl2-doom
atomic_patch -p1 ../patches/11.diff
cd src
if [[ "${target}" == *-mingw* ]]; then
    make -f makefile.mingw -j${nproc} CC="${CC}"
else
    make -j${nproc}
fi
install -Dvm 755 "sdl2-doom${exeext}" "${bindir}/doom${exeext}"
cd ..
install -Dvm 644 "${WORKSPACE}/srcdir/doom1.wad" -t "${prefix}/share/doom"
install_license License.md
"""

# These are the platforms we will build for by default, unless further restrictions are
# imposed by the user. Grabbing the list from BinaryBuilder.jl.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("doom", :doom),
    FileProduct("share/doom/doom1.wad", :doom1_wad),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll")),
    Dependency(PackageSpec(name="SDL2_mixer_jll")),
]

# Build the tarballs, and possibly a `build.jl` file.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
