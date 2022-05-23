# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Raylib"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/raysan5/raylib.git",
              "0851960397f02a477d80eda2239f90fae14dec64"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/raylib/src/

atomic_patch -p1 ../../patches/add-missing-header.patch
atomic_patch -p1 ../../patches/make-install-everywhere.patch
atomic_patch -p2 ../../patches/make-ldflags-windows.patch

export CFLAGS="-D_POSIX_C_SOURCE=200112L"
if [[ "${target}" == *-freebsd* ]]; then
    # Allow definition of `u_char`, `u_short`, `u_int`, and `u_long` in sys/types.h
    CFLAGS="${CFLAGS} -D__BSD_VISIBLE"
fi
CFLAGS="${CFLAGS} -DSUPPORT_EVENTS_AUTOMATION -DSUPPORT_FILEFORMAT_BMP -DSUPPORT_FILEFORMAT_JPG"

FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    # raylib.rc.data is broken for x64, remove it from compilation
    sed -i 's+$(RAYLIB_RES_FILE)+ +g' Makefile
    # we need to specify the OS in the flags to make for Windows
    FLAGS+=(OS=Windows_NT)
fi
make -j${nproc} USE_EXTERNAL_GLFW=TRUE PLATFORM=PLATFORM_DESKTOP RAYLIB_LIBTYPE=SHARED RAYLIB_MODULE_RAYGUI=TRUE RAYLIB_MODULE_PHYSAC=TRUE "${FLAGS[@]}"
make install RAYLIB_LIBTYPE=SHARED DESTDIR="${prefix}" RAYLIB_INSTALL_PATH="${libdir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->arch(p)=="armv6l")

# The products that we will ensure are always built
products = [
    LibraryProduct(["libraylib","raylib"], :libraylib)
]

x11_platforms = filter(p ->Sys.islinux(p) || Sys.isfreebsd(p), platforms)
# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"); platforms=filter(Sys.islinux, platforms))
    Dependency(PackageSpec(name="Mesa_jll", uuid="78dcde23-ec64-5e07-a917-6fe22bbc0f45"); platforms=filter(Sys.iswindows, platforms))
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"); platforms=x11_platforms)
    Dependency(PackageSpec(name="Xorg_libXrandr_jll", uuid="ec84b674-ba8e-5d96-8ba1-2a689ba10484"); platforms=x11_platforms)
    Dependency(PackageSpec(name="Xorg_libXi_jll", uuid="a51aa0fd-4e3c-5386-b890-e753decda492"); platforms=x11_platforms)
    Dependency(PackageSpec(name="Xorg_libXcursor_jll", uuid="935fb764-8cf2-53bf-bb30-45bb1f8bf724"); platforms=x11_platforms)
    Dependency(PackageSpec(name="Xorg_libXinerama_jll", uuid="d1454406-59df-5ea1-beac-c340f2130bc3"); platforms=x11_platforms)
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
    Dependency(PackageSpec(name="GLFW_jll", uuid="0656b61e-2033-5cc2-a64a-77c0f6c09b89"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
