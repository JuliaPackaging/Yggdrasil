# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libgraphicsmagic"
version = v"1.3.36"

# Collection of sources required to complete build
sources = [
    ArchiveSource("ftp://ftp.icm.edu.pl/pub/unix/graphics/GraphicsMagick/1.3/GraphicsMagick-1.3.36.tar.gz", "1e6723c48c4abbb31197fadf8396b2d579d97e197123edc70a4f057f0533d563")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/GraphicsMagick*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(!Sys.iswindows, supported_platforms(; experimental=true))
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libGraphicsMagickWand", :libGraphicsMagicWand),
    LibraryProduct("libGraphicsMagick++", :libGraphicsMagicPlusPlus),
    LibraryProduct("libGraphicsMagick", :libGraphicsMagic),
    ExecutableProduct("gm", :gm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="libwebp_jll", uuid="c5f90fcd-3b7e-5836-afba-fc50a0988cb2"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="FreeType2_jll", uuid="d7e528f0-a631-5988-bf34-fe36492bcfd7"); compat="2.10.4")
    Dependency(PackageSpec(name="Ghostscript_jll", uuid="61579ee1-b43e-5ca0-a5da-69d92c66a64b"))
    Dependency(PackageSpec(name="Xorg_libXext_jll", uuid="1082639a-0dae-5f34-9b06-72781eeb8cb3"))
    Dependency(PackageSpec(name="Xorg_libSM_jll", uuid="c834827a-8449-5923-a945-d239c165b7dd"))
    # TODO: v4.3.0 is available, use that next time
    Dependency("Libtiff_jll"; compat="4.1.0")
    Dependency(PackageSpec(name="LittleCMS_jll", uuid="d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"))
    Dependency("Bzip2_jll", v"1.0.7"; compat="1.0.7")
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800"))
    Dependency(PackageSpec(name="Libtool_jll", uuid="a76c16ae-fb8f-5ff0-8826-da3b7a640f0b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
