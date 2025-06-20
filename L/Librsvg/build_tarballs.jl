# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Librsvg"
version = v"2.58.5"

# Collection of sources required to build librsvg
sources = [
    ArchiveSource("https://download.gnome.org/sources/librsvg/$(version.major).$(version.minor)/librsvg-$(version).tar.xz",
                  "224233a0e347d38c415f15a49f0e0885313e3ecc18f3192055f9304dd2f3a27a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/librsvg-*/

autoreconf -fiv

# Delete misleading libtool files
rm -vf ${prefix}/lib/*.la

# On most platforms we have to use `${rust_target}` as `host`
FLAGS=(--host=${rust_target})
if [[ "${target}" == *-mingw* ]]; then
    # On Windows using `${rust_target}` wouldn't work:
    #
    #     Invalid configuration `x86_64-pc-windows-gnu': Kernel `windows' not known to work with OS `gnu'.
    #
    # Then we have to use `RUST_TARGET` to set the Rust target.  I haven't found
    # a combination host and RUST_TARGET that would work on all platforms.  If
    # you do, let me know!
    FLAGS=(--host=${target} RUST_TARGET="${rust_target}" LIBS="-luserenv -lbcrypt")
fi

# MUSL-specific Rust linking fix - force dynamic linking instead of static
if [[ "${target}" == *-musl ]]; then
    echo "========== MUSL DYNAMIC LINKING FIX =========="
    
    # Remove potentially conflicting libgcc_s.so.1 from destdir
    if [ -f "${prefix}/lib/libgcc_s.so.1" ]; then
        echo "Removing conflicting libgcc_s.so.1 from ${prefix}/lib"
        rm -f "${prefix}/lib/libgcc_s.so"* 
    fi
    
    # Create .cargo/config.toml to force dynamic linking for musl
    mkdir -p .cargo
    cat > .cargo/config.toml << 'EOF'
[target.aarch64-unknown-linux-musl]
rustflags = [
    "-C", "target-feature=-crt-static",
    "-C", "link-arg=-Wl,--as-needed"
]

[target.x86_64-unknown-linux-musl]
rustflags = [
    "-C", "target-feature=-crt-static", 
    "-C", "link-arg=-Wl,--as-needed"
]

[target.i686-unknown-linux-musl]
rustflags = [
    "-C", "target-feature=-crt-static",
    "-C", "link-arg=-Wl,--as-needed"
]
EOF

    # Set environment variables for Rust with dynamic linking flags
    export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_RUSTFLAGS="-C target-feature=-crt-static -C link-arg=-Wl,--as-needed"
    export CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_RUSTFLAGS="-C target-feature=-crt-static -C link-arg=-Wl,--as-needed"
    export CARGO_TARGET_I686_UNKNOWN_LINUX_MUSL_RUSTFLAGS="-C target-feature=-crt-static -C link-arg=-Wl,--as-needed"
    
    # Set RUSTFLAGS for final linking with runtime library path
    export RUSTFLAGS="-C target-feature=-crt-static -C link-arg=-Wl,--as-needed -C link-arg=-Wl,--enable-new-dtags -C link-arg=-Wl,--rpath=${prefix}/lib"
    
    # Filter LD_LIBRARY_PATH to avoid ABI conflicts during build
    FILTERED_LD_LIBRARY_PATH=""
    IFS=':' read -ra PATHS <<< "${LD_LIBRARY_PATH}"
    for path in "${PATHS[@]}"; do
        if [[ "$path" != *"/workspace/destdir/"* ]] && [[ "$path" != "" ]]; then
            if [[ -z "$FILTERED_LD_LIBRARY_PATH" ]]; then
                FILTERED_LD_LIBRARY_PATH="$path"
            else
                FILTERED_LD_LIBRARY_PATH="$FILTERED_LD_LIBRARY_PATH:$path"
            fi
        fi
    done
fi

./configure \
    --build=${MACHTYPE} \
    --prefix=${prefix} \
    --disable-static \
    --enable-pixbuf-loader \
    --disable-introspection \
    --disable-gtk-doc-html \
    --enable-shared \
    "${FLAGS[@]}"
make
make install
install_license COPYING.LIB
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# We dont have all dependencies for armv6l
filter!(p -> arch(p) != "armv6l", platforms)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    # The main event
    LibraryProduct("librsvg-2", :librsvg),

    # This is named `.so` even on darwin, so do it as a FileProduct.....sigh
    FileProduct(["lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.so",
                 "lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.dll"], :libpixbufloader_svg),
    #LibraryProduct("libpixbufloader-svg", :libpixbufloader_svg, ["lib/gdk-pixbuf-2.0/2.10.0/loaders"]),

    # And to round it out, let's get an executable as well!
    ExecutableProduct("rsvg-convert", :rsvg_convert),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need to run `gdk-pixbuf-query-loaders`
    HostBuildDependency("gdk_pixbuf_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("gdk_pixbuf_jll"),
    Dependency("Pango_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers=[:c, :rust])
