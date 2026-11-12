# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenSlide"
version = v"3.4.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openslide/openslide/releases/download/v3.4.1/openslide-3.4.1.tar.gz", "fed08fab8a9b1ded95a34e196652291127ebe392c11f9bc13d26e760295a102d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openslide-3.4.1/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Experimental platforms cannot be used with Julia v1.5-.
# Change `julia_compat` to require at least Julia v1.6
# platforms = filter(!Sys.isapple, supported_platforms())
# Remove this when we build a newer version for which we can target the former
# experimental platforms
platforms = [
    # glibc Linuces
    Platform("i686", "linux"),
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("armv7l", "linux"),
    Platform("powerpc64le", "linux"),

    # musl Linuces
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),

    # BSDs
    Platform("x86_64", "freebsd"),

    # Windows
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libopenslide", :libopenslide)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    # TODO: v4.3.0 is available, use that next time
    Dependency("Libtiff_jll"; compat="4.1.0")
    Dependency(PackageSpec(name="OpenJpeg_jll", uuid="643b3616-a352-519d-856d-80112ee9badc"))
    Dependency(PackageSpec(name="gdk_pixbuf_jll", uuid="da03df04-f53b-5353-a52f-6a8b0620ced0"))
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"); compat="~2.13.6")
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8"))
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a"))
    Dependency("Glib_jll"; compat="2.59")
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
