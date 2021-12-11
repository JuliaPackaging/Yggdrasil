# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Wine is a bit of a pain to build; it requires a two-and-a-half step process;
# we first build the 64-bit version of Wine part-way, use its BUILD DIRECTORY
# (not the result of `make install`, the result of `make`!) to build 32-bit
# Wine, install and bundle that version up, then resume the 64-bit build.

# We also don't support passing explicit targets in
SAFE_ARGS = [a for a in ARGS if startswith(a, "-") && !startswith(a, "--deploy")]
platform_spec = [a for a in ARGS if !startswith(a, "-")]
is_meta = any(a->startswith(a, "--meta-json"), ARGS)
requested_platforms = map(p->parse(Platform, p; validate_strict=true), platform_spec)

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

platform32_musl = Platform("i686", "linux"; libc="musl")
platform64_musl = Platform("x86_64", "linux"; libc="musl")

platform32_glibc = Platform("i686", "linux")
platform64_glibc = Platform("x86_64", "linux")

all_platforms = [
    platform64_musl,
    platform64_glibc
]

platform_map = Dict(
    platform64_musl => platform32_musl,
    platform64_glibc => platform32_glibc
)

# In meta mode, note all supported platforms.
platforms = all_platforms

if !is_meta
    # TODO: Make it possible to build multiple platforms in one invocation.
    if isempty(requested_platforms)
        @info "No platform specified; defaulting to musl."
        platform64 = platform64_musl
    elseif length(requested_platforms) != 1
        error("This build script is special and only supports one platform at a time.")
    else
        platform64 = requested_platforms[1]
    end

    platform32 = platform_map[platform64]

    wine64_build_script = raw"""
    # First, build wine64, making the actual build directory itself the thing we will install.
    mkdir $WORKSPACE/destdir/wine64
    cd $WORKSPACE/destdir/wine64
    # N.B.: The --build=${target} is technically wrong here, but
    # because we support both glibc and musl exectuables in the
    # build environment, everything goes through ok and doesn't
    # trigger wine's cross compile detection (which would require
    # a more complicated bootstrap process).
    $WORKSPACE/srcdir/wine/configure --prefix=${prefix} --build=${target} --host=${target} --without-x --without-freetype --enable-win64
    make -j${nproc}
    """

    # package up the wine64 build directory itself:
    product_hashes = build_tarballs(copy(SAFE_ARGS), "BuildTmpWine64Build", version, sources, wine64_build_script, [platform64], products, dependencies; skip_audit=true, preferred_gcc_version=v"11.1")

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

    product_hashes = build_tarballs(copy(SAFE_ARGS), "BuildTmpWine32", version, sources, wine32_script, [platform32], wine32_products, dependencies; skip_audit=true, preferred_gcc_version=v"11.1")
    wine32_path, wine32_hash = product_hashes[platform32]
    push!(sources, ArchiveSource(joinpath("products", wine32_path), wine32_hash))
end

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

build_tarballs(copy(SAFE_ARGS), "Wine", version, sources, script, platforms, final_products, dependencies, preferred_gcc_version=v"11.1")
