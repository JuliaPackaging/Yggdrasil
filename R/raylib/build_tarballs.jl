# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Raylib"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/raysan5/raylib.git", "0851960397f02a477d80eda2239f90fae14dec64")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd raylib/src/
CFLAGS="-D_POSIX_C_SOURCE=199309L -I${prefix}/include" make -j${nproc} USE_EXTERNAL_GLFW=TRUE PLATFORM=PLATFORM_DESKTOP RAYLIB_LIBTYPE=SHARED
DESTDIR="${prefix}" make install RAYLIB_LIBTYPE=SHARED
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libraylib", :libraylib)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"))
    Dependency(PackageSpec(name="Mesa_jll", uuid="78dcde23-ec64-5e07-a917-6fe22bbc0f45"))
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"))
    Dependency(PackageSpec(name="Xorg_libXrandr_jll", uuid="ec84b674-ba8e-5d96-8ba1-2a689ba10484"))
    Dependency(PackageSpec(name="Xorg_libXi_jll", uuid="a51aa0fd-4e3c-5386-b890-e753decda492"))
    Dependency(PackageSpec(name="Xorg_libXcursor_jll", uuid="935fb764-8cf2-53bf-bb30-45bb1f8bf724"))
    Dependency(PackageSpec(name="Xorg_libXinerama_jll", uuid="d1454406-59df-5ea1-beac-c340f2130bc3"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
    Dependency(PackageSpec(name="GLFW_jll", uuid="0656b61e-2033-5cc2-a64a-77c0f6c09b89"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
