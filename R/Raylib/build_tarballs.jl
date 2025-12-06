# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Raylib"
version = v"5.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/raysan5/raylib.git",
              "c1ab645ca298a2801097931d1079b10ff7eb9df8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/raylib/src/

make -j${nproc} PLATFORM=PLATFORM_DESKTOP CC=gcc RAYLIB_LIBTYPE=STATIC -B
make -j${nproc} PLATFORM=PLATFORM_DESKTOP CC=gcc RAYLIB_LIBTYPE=SHARED -B

make install RAYLIB_LIBTYPE=STATIC DESTDIR="${prefix}" RAYLIB_INSTALL_PATH="${libdir}"
make install RAYLIB_LIBTYPE=SHARED DESTDIR="${prefix}" RAYLIB_INSTALL_PATH="${libdir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [Platform("x86_64", "linux")]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libraylib","raylib"], :libraylib)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"); platforms=platforms)
    Dependency(PackageSpec(name="Mesa_jll", uuid="78dcde23-ec64-5e07-a917-6fe22bbc0f45"); platforms=platforms)
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"); platforms=platforms)
    Dependency(PackageSpec(name="Xorg_libXrandr_jll", uuid="ec84b674-ba8e-5d96-8ba1-2a689ba10484"); platforms=platforms)
    Dependency(PackageSpec(name="Xorg_libXi_jll", uuid="a51aa0fd-4e3c-5386-b890-e753decda492"); platforms=platforms)
    Dependency(PackageSpec(name="Xorg_libXcursor_jll", uuid="935fb764-8cf2-53bf-bb30-45bb1f8bf724"); platforms=platforms)
    Dependency(PackageSpec(name="Xorg_libXinerama_jll", uuid="d1454406-59df-5ea1-beac-c340f2130bc3"); platforms=platforms)
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
    Dependency(PackageSpec(name="GLFW_jll", uuid="0656b61e-2033-5cc2-a64a-77c0f6c09b89"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
