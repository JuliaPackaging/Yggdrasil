# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Wine is a bit of a pain to build; it requires a two-and-a-half step process;
# we first build the 64-bit version of Wine part-way, use its BUILD DIRECTORY
# (not the result of `make install`, the result of `make`!) to build 32-bit
# Wine, install and bundle that version up, then resume the 64-bit build.

# We also don't support passing explicit targets in
SAFE_ARGS = [a for a in ARGS if startswith(a, "-")]

version = v"7.0-rc1"
sources = Any[
    GitSource("https://github.com/wine-mirror/wine.git", "533616d23f9832596e41f839356830c7679df930"),
]

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("wine64", :wine64, "wine64/loader"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("GnuTLS_jll"),
]

platform32 = Platform("i686", "linux"; libc="musl")
platform64 = Platform("x86_64", "linux"; libc="musl")

wine64_build_script = raw"""
# First, build wine64, making the actual build directory itself the thing we will install.
mkdir $WORKSPACE/destdir/wine64
cd $WORKSPACE/destdir/wine64
$WORKSPACE/srcdir/wine/configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --without-x --without-freetype --enable-win64
make -j${nproc}
"""

# package up the wine64 build directory itself:
product_hashes = build_tarballs(copy(SAFE_ARGS), "Wine64Build", version, sources, wine64_build_script, [platform64], products, dependencies; skip_audit=true, preferred_gcc_version=v"11.1")

@show product_hashes

# Include that tarball as one of the sources we need to include:
wine64_build_path, wine64_build_hash = product_hashes[platform64]
push!(sources, ArchiveSource(joinpath("products", wine64_build_path), wine64_build_hash))

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
make -j${nproc} install
"""

wine32_products = Product[
   ExecutableProduct("wine", :wine, "wine32/loader"),
]

product_hashes = build_tarballs(copy(SAFE_ARGS), "Wine32", version, sources, wine32_script, [platform32], wine32_products, dependencies; skip_audit=true, preferred_gcc_version=v"11.1")
wine32_path, wine32_hash = product_hashes[platform32]
push!(sources, ArchiveSource(joinpath("products", wine32_path), wine32_hash))

# Finally, install both:
script = raw"""
cp -r $WORKSPACE/srcdir/wine32/* ${prefix}/
cd $WORKSPACE/srcdir/wine64
make -j${nproc} install
install_license $WORKSPACE/srcdir/wine/LICENSE
install_license $WORKSPACE/srcdir/wine/COPYING.LIB
"""

final_products = Product[
    ExecutableProduct("wine64", :wine64),
    ExecutableProduct("wine", :wine),
]

build_tarballs(copy(SAFE_ARGS), "Wine", version, sources, script, [platform64], final_products, dependencies, preferred_gcc_version=v"11.1")
