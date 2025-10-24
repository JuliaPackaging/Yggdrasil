
using BinaryBuilder, Pkg

name = "Doom"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AlexOberhofer/sdl2-doom.git",
              "da7732ee6318371db2ee04ec4702c6064245846b")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/sdl2-doom/src
if [[ "${target}" == *-mingw* ]]; then
    make -f makefile.mingw -j${nproc}
    cp sdl2-doom.exe ${bindir}/doom.exe
else
    make -j${nproc}
    cp sdl2-doom ${bindir}/doom
fi
"""

# These are the platforms we will build for by default, unless further restrictions are
# imposed by the user. Grabbing the list from BinaryBuilder.jl.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("doom", :doom)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll")),
    Dependency(PackageSpec(name="SDL2_mixer_jll")),
]

# Build the tarballs, and possibly a `build.jl` file.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false)
