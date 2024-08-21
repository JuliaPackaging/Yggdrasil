# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

function build_harfbuzz(ARGS, name::String)

    icu = name == "HarfBuzz_ICU"

    version = v"8.3.1"

    # Collection of sources required to build Harfbuzz
    sources = [
        ArchiveSource("https://github.com/harfbuzz/harfbuzz/releases/download/$(version)/harfbuzz-$(version).tar.xz",
                      "f73e1eacd7e2ffae687bc3f056bb0c705b7a05aee86337686e09da8fc1c2030c"),
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
    platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(; experimental=true))

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
        Dependency("Cairo_jll"),
        Dependency("Fontconfig_jll"),
        Dependency("FreeType2_jll"; compat="2.10.4"),
        Dependency("Glib_jll"; compat="2.68.1"),
        Dependency("Graphite2_jll"),
        Dependency("Libffi_jll"; compat="~3.2.2"),
        BuildDependency("Xorg_xorgproto_jll"),
    ]

    if icu
        append!(dependencies, [
            Dependency("HarfBuzz_jll"; compat="$(version)"),
            Dependency("ICU_jll"; compat="69.1.0"),
        ])
    end

    # Build the tarballs, and possibly a `build.jl` as well.
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5", julia_compat="1.6", clang_use_lld=false)
end
