# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Wine is a bit of a pain to build; it requires a two-and-a-half step process;
# we first build the 64-bit version of Wine part-way, use its BUILD DIRECTORY
# (not the result of `make install`, the result of `make`!) to build 32-bit
# Wine, install and bundle that version up, then resume the 64-bit build.

# We also don't support passing explicit targets in
SAFE_ARGS = [a for a in ARGS if startswith(a, "-")]

version = v"3.21"
sources = [
    "https://github.com/wine-mirror/wine.git" => "ea9253d6d3c9bb60d98b0d917292fc0b4babb3dd",
]

# The products that we will ensure are always built
products(prefix) = Product[
    ExecutableProduct(prefix, "wine64", :wine64),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.2/build_Zlib.v1.2.11.jl",
    "https://github.com/SimonDanisch/LibpngBuilder/releases/download/v1.0.1/build_libpng.v1.6.31.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/JpegTurbo-v2.0.1-0/build_JpegTurbo.v2.0.1.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GnuTLS-v3.6.5-0/build_GnuTLS.v3.6.5.jl",
]

platform32 = Linux(:i686; libc=:musl)
platform64 = Linux(:x86_64; libc=:musl)

wine64_build_script = raw"""
# First, build wine64, making the actual build directory itself the thing we will install.
mkdir $WORKSPACE/destdir/wine64
cd $WORKSPACE/destdir/wine64
$WORKSPACE/srcdir/wine/configure --prefix=${prefix} --host=${target} --without-x --without-freetype --enable-win64
make -j${nproc}
"""

# package up the wine64 build directory itself:
product_hashes = build_tarballs(copy(SAFE_ARGS), "Wine64Build", version, sources, wine64_build_script, [platform64], products, dependencies; skip_audit=true)

# Include that tarball as one of the sources we need to include:
wine64_build_path, wine64_build_hash = product_hashes[triplet(platform64)]
push!(sources, joinpath("products", wine64_build_path) => wine64_build_hash)

# Next, build wine32, without wine64, then use those tools to build wine32 WITH wine64
wine32_script = raw"""
# Next, build wine32, linking against the previously included wine64 stuff:
mkdir $WORKSPACE/srcdir/wine32_only
cd $WORKSPACE/srcdir/wine32_only
$WORKSPACE/srcdir/wine/configure --host=${target}  --without-x --without-freetype
make -j${nproc}

mkdir $prefix/wine32
cd $prefix/wine32
$WORKSPACE/srcdir/wine/configure --prefix=${prefix}/wine32 --host=${target} --without-x --without-freetype --with-wine64=$WORKSPACE/srcdir/wine64 --with-wine-tools=$WORKSPACE/srcdir/wine32_only
make -j${nproc}
make install
"""

product_hashes = build_tarballs(copy(SAFE_ARGS), "Wine32", version, sources, wine32_script, [platform32], products, dependencies; skip_audit=true)
wine32_path, wine32_hash = product_hashes[triplet(platform32)]
push!(sources, joinpath("products", wine32_path) => wine32_hash)

# Finally, install both:
script = raw"""
cp -r $WORKSPACE/srcdir/wine32/* ${prefix}/
cd $WORKSPACE/srcdir/wine64
make install
"""

build_tarballs(copy(SAFE_ARGS), "Wine", version, sources, script, [platform64], products, dependencies)
