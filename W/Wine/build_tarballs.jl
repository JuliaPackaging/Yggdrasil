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

version = v"7.13"
sources = Any[
    GitSource("https://github.com/JuliaComputing/wine-staging.git", "e31912369024e2486f3f96a14b6e6f82b6c463de"),
    DirectorySource("./bundled")
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

platform64_darwin = Platform("x86_64", "macos")

all_platforms = [
    platform64_musl,
    platform64_glibc,
    platform64_darwin
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

    if platform64 != platform64_darwin
        # No wine32 build for darwin at the moment.

        platform32 = platform_map[platform64]

        wine64_build_script = raw"""
        cd $WORKSPACE/srcdir/wine-staging
        atomic_patch -p1 $WORKSPACE/srcdir/patches/hwcap2.patch

        # First, build wine64, making the actual build directory itself the thing we will install.
        mkdir $WORKSPACE/destdir/wine64
        cd $WORKSPACE/destdir/wine64
        # N.B.: The --build=${target} is technically wrong here, but
        # because we support both glibc and musl exectuables in the
        # build environment, everything goes through ok and doesn't
        # trigger wine's cross compile detection (which would require
        # a more complicated bootstrap process).
        $WORKSPACE/srcdir/wine-staging/configure --prefix=${prefix} --build=${target} --host=${target} --without-x --without-freetype --enable-win64
        make -j${nproc}
        """

        # package up the wine64 build directory itself:
        product_hashes = build_tarballs(copy(SAFE_ARGS), "BuildTmpWine64Build", version, sources, wine64_build_script, [platform64], products, dependencies; skip_audit=true, preferred_gcc_version=v"11.1")

        # Include that tarball as one of the sources we need to include:
        wine64_build_path, wine64_build_hash = product_hashes[platform64]
        push!(sources, ArchiveSource(joinpath("products", wine64_build_path), wine64_build_hash))

        # Next, build wine32, without wine64, then use those tools to build wine32 WITH wine64
        wine32_script = raw"""
        cd $WORKSPACE/srcdir/wine-staging
        atomic_patch -p1 $WORKSPACE/srcdir/patches/hwcap2.patch

        # Next, build wine32, linking against the previously included wine64 stuff:
        mkdir $WORKSPACE/srcdir/wine32_only
        cd $WORKSPACE/srcdir/wine32_only
        $WORKSPACE/srcdir/wine-staging/configure --host=${target} --without-x --without-freetype
        make -j${nproc}

        mkdir $prefix/wine32
        cd $prefix/wine32
        $WORKSPACE/srcdir/wine-staging/configure --prefix=${prefix}/wine32 --host=${target} --without-x --without-freetype --with-wine64=$WORKSPACE/srcdir/wine64 --with-wine-tools=$WORKSPACE/srcdir/wine32_only
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

    platforms = [platform64]
end

# Finally, install both:
script = raw"""
cd $WORKSPACE/srcdir/wine-staging
atomic_patch -p1 $WORKSPACE/srcdir/patches/hwcap2.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/darwin.patch

if [[ "${target}" == *darwin* ]]; then
    # On macOS, we currently do not support 32-bit wine. It is unclear whether
    # this is supported in upstream wine (though it is supported in CrossOver,
    # the commercial wine version). Because of that, we can skip the complicated
    # boostrap procedure above and just build everything right here. However,
    # we do have to do a bit of extra work to sucessfully cross-compile for
    # darwin, since we can't rely on natively running the tools.

    # Go to wine_tools directory
    mkdir $WORKSPACE/wine_tools
    cd $WORKSPACE/wine_tools

    # winebuild will use {nm, ld, as} indiscriminately and expect those to be
    # the host tools, so put those on the PATH.
    mkdir aliases
	ln -s $(which x86_64-linux-musl-nm) aliases/nm
	ln -s $(which x86_64-linux-musl-ld) aliases/ld
	ln -s $(which x86_64-linux-musl-as) aliases/as
    export OLD_PATH=$PATH
    export PATH=$PWD/aliases:$PATH
    ${WORKSPACE}/srcdir/wine-staging/configure --build=x86_64-linux-musl --host=x86_64-linux-musl CC=x86_64-linux-musl-gcc LD=x86_64-linux-musl-ld AS=x86_64-linux-musl-as --enable-win64 --without-x --without-freetype
    make -j${nproc} CC=x86_64-linux-musl-gcc LD=x86_64-linux-musl-ld AS=x86_64-linux-musl-as
    export PATH=$OLD_PATH

    # Ok, now we can actually do the proper build of wine.
    cd $WORKSPACE/srcdir/wine-staging
    ./configure --build=${MACHTYPE} --prefix=${prefix} --host=${target} --without-x --without-freetype --with-wine-tools=$WORKSPACE/wine_tools --enable-win64
    make -j${nproc}
else
    cp -r $WORKSPACE/srcdir/wine32/* ${prefix}/
    cd $WORKSPACE/srcdir/wine64
fi

make -j${nproc} install
install_license $WORKSPACE/srcdir/wine-staging/LICENSE
install_license $WORKSPACE/srcdir/wine-staging/COPYING.LIB
"""

final_products = Product[
    ExecutableProduct("wine64", :wine64),
# Currently the macos build is wine64 only, so let's leave it at that.
#    ExecutableProduct("wine", :wine),
]

build_tarballs(ARGS, "Wine", version, sources, script, platforms, final_products, dependencies, preferred_gcc_version=v"11.1")
