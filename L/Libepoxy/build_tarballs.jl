# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libepoxy"
version = v"1.5.10"
# We bumped the version number to build for riscv64
ygg_version = v"1.5.11"

# Collection of sources required to build Libepoxy
sources = [
    GitSource("https://github.com/anholt/libepoxy", "c84bc9459357a40e46e2fec0408d04fbdde2c973"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libepoxy

# meson unconditionally (?) adds the command line argument
# `-Werror=unused-command-line-argument`. That would be fine, except
# that we (the `cc` script) add `-Wl,-sdk_version,11.0` on Darwin,
# which is actually unused when meson checks for supported compiler
# options. This means that each such check fails, and meson won't use
# any options. That's mostly fine, except for the option
# `-Wno-int-conversion` which is required by the source code.
#
# The code below modifies the `cc` script to filter out the option
# `-Werror=unused-command-line-argument`. This should arguably either
# happen by default, or `cc` should only add the
# `-Wl,-sdk_version,11.0` when the linker is actually called.
#
# We modify `cc` on all architectures to prevent possible similar
# errors there.

ccfile=$(which cc)
{
    head -n 16 ${ccfile}
    cat <<'EOT'
        # Remove the meson option we don't like
        newargs=()
        for arg in "${ARGS[@]}"; do
            if [[ "${arg}" != "-Werror=unused-command-line-argument" ]]; then
                newargs+=("${arg}")
            fi
        done
        ARGS=("${newargs[@]}")
EOT
    tail -n +17 ${ccfile}
} >${ccfile}.tmp
# Use `cat; rm` instead of `mv` to use the same file to keep symlinks, file permissions etc.
cat ${ccfile}.tmp >${ccfile}
rm ${ccfile}.tmp

ccfile=$(which clang)
{
    head -n 16 ${ccfile}
    cat <<'EOT'
        # Remove the meson option we don't like
        newargs=()
        for arg in "${ARGS[@]}"; do
            if [[ "${arg}" != "-Werror=unused-command-line-argument" ]]; then
                newargs+=("${arg}")
            fi
        done
        ARGS=("${newargs[@]}")
EOT
    tail -n +17 ${ccfile}
} >${ccfile}.tmp
# Use `cat; rm` instead of `mv` to use the same file to keep symlinks, file permissions etc.
cat ${ccfile}.tmp >${ccfile}
rm ${ccfile}.tmp

mkdir build && cd build
env CC=cc meson .. -Dtests=false --buildtype=release --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libepoxy", :libepoxy),
]

linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_freebsd),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6")
