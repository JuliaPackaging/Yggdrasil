using BinaryBuilder, Pkg

name = "Gnuplot"
version = v"5.4.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/gnuplot/gnuplot/$(version)/gnuplot-$(version).tar.gz",
                  "02fc27918200ed64d8f0c3b84fe81b95b59cd47ad99f270939ae497c19f27419"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnuplot-*

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # Delete system libexpat to avoid confusion
    rm /usr/lib/libexpat.so*
elif [[ "${target}" == *-mingw* ]]; then
    # Apply patch from https://github.com/msys2/MINGW-packages/blob/5dcff9fd637714972b113c6d3fbf6db17e9b707a/mingw-w64-gnuplot/01-gnuplot.patch
    atomic_patch -p1 ../patches/01-gnuplot.patch
    autoreconf -fiv
fi

# FIXME: no Qt Tools artifacts available for these platforms (missing either uic or lrelease)
case "$target" in
    aarch64-apple-darwin*) args+=(--with-qt=no);;
esac

export LIBS='-liconv'

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ${args[@]}

cd src
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [ExecutableProduct("gnuplot", :gnuplot)]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="Libcerf_jll", uuid="af83a40a-c4c4-57a0-81df-2309fbd279e3")),
    Dependency(PackageSpec(name="LibGD_jll", uuid="16339573-6216-525a-b38f-30b6f6b71b5f")),
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a")),
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531")),
    BuildDependency(PackageSpec(name="Qt5Tools_jll", uuid="a9c6e4b1-b2fb-56d5-96a9-25f276f13840")),
    Dependency(PackageSpec(name="Qt5Svg_jll", uuid="3af4ccab-a251-578e-a514-ea85a0ba79ee")),
]

# Build the tarballs, and possibly a `build.jl` as well.
julia_build = 0  # NOTE: increment on rebuild
build_tarballs(
    ARGS, name, VersionNumber(version.major, version.minor, 100 * version.patch + julia_build),
    sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"8"
)
