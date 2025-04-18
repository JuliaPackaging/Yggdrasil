# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

function build_harfbuzz(ARGS, name::String)

    icu = name == "HarfBuzz_ICU"

    version = v"8.5.0"
    # Bump Yggdrasil version because we updated libffi_jll
    ygg_version = v"8.5.1"

    # Collection of sources required to build Harfbuzz
    sources = [
        ArchiveSource("https://github.com/harfbuzz/harfbuzz/releases/download/$(version)/harfbuzz-$(version).tar.xz",
                      "77e4f7f98f3d86bf8788b53e6832fb96279956e1c3961988ea3d4b7ca41ddc27"),
        DirectorySource("../bundled"),
    ]

    # Bash recipe for building across all platforms
    # Side note: this is a great use-case for
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/778
    script = "ICU=$(icu)\n" * raw"""
cd $WORKSPACE/srcdir/harfbuzz-*/

# On MacOS, bypass broken check for CoreText
if [[ "${target}" == *-apple-darwin* ]]; then
    atomic_patch -p1 ../patches/coretext-check-bypass.patch
fi

mkdir build && cd build
meson .. \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --buildtype=release \
    -Dcairo=enabled \
    -Dfreetype=enabled \
    -Dglib=enabled \
    -Dgobject=enabled \
    -Dgraphite=enabled \
    -Dintrospection=disabled \
    -Ddocs=disabled \
    -Dtests=disabled \
    -Dicu=auto \
    -Dicu_builtin=false \
    -Dcoretext=enabled \
    -Dgdi=enabled \
    -Ddirectwrite=enabled
ninja -j${nproc}
if [[ "${ICU}" == true ]]; then
    # Remove directories with symbol files (they confuse the `cp` command below)
    rm -rf src/libharfbuzz-icu*${dlext}*.p
    # Manually install only ICU-related files
    cp src/libharfbuzz-icu*${dlext}* ${libdir}/.
    cp meson-private/harfbuzz-icu.pc ${prefix}/lib/pkgconfig/.
    cp ../src/hb-icu.h ${includedir}/harfbuzz/.
else
    ninja install
fi
"""

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = supported_platforms()

    # The products that we will ensure are always built
    products = if icu
        [
            LibraryProduct("libharfbuzz-icu", :libharfbuzz_icu),
        ]
    else
        [
            LibraryProduct("libharfbuzz", :libharfbuzz),
            LibraryProduct("libharfbuzz-subset", :libharfbuzz_subset),
            LibraryProduct("libharfbuzz-gobject", :libharfbuzz_gobject),
        ]
    end

    # Dependencies that must be installed before this package can be built
    dependencies = [
        Dependency("Cairo_jll"; compat="1.18.4"),
        Dependency("Fontconfig_jll"; compat="2.15.0"),
        Dependency("FreeType2_jll"; compat="2.13.3"),
        Dependency("Glib_jll"; compat="2.84.0"),
        Dependency("Graphite2_jll"; compat="1.3.14"),
        Dependency("Libffi_jll"; compat="~3.4.7"),
        BuildDependency("Xorg_xorgproto_jll"),
    ]

    if icu
        append!(dependencies, [
            Dependency("HarfBuzz_jll"; compat="$(version)"),
            Dependency("ICU_jll"; compat="76.2"),
        ])
    end

    # Build the tarballs, and possibly a `build.jl` as well.
    build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
                   clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")
end
