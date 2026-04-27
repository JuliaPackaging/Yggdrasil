# BinaryBuilder.jl recipe for libsie_z_jll.
using BinaryBuilder

#library
name    = "libsie_z"
version = v"0.3.3"
repo      = "https://github.com/efollman/libsie-z.git"
tree_hash = "76034b20049e95da6a0380bc2d6c2634d227781c"

# zig tarball
zig_version = "0.15.2"
zig_sha256  = "02aa270f183da276e5b5920b1dac44a63f1a49e55050ebde3aecc9eb82f93239"
zig_url     = "https://ziglang.org/download/$(zig_version)/zig-x86_64-linux-$(zig_version).tar.xz"

sources = [
    GitSource(repo, tree_hash),
    ArchiveSource(zig_url, zig_sha256; unpack_target = "zig"),
]

# Build script
# Runs inside the BinaryBuilder sandbox. `${target}` is the BB GNU triple,
# which `build.zig` translates to a Zig target via `-Dtriple=`.
script = raw"""
# Put the Zig toolchain (extracted from the ArchiveSource above) on PATH.
# The tarball unpacks to $WORKSPACE/srcdir/zig/zig-*-<version>/zig.
export PATH=$(echo $WORKSPACE/srcdir/zig/zig-*):$PATH

cd $WORKSPACE/srcdir/libsie-z*

# Zig's own cache lives under $HOME inside the sandbox.
export ZIG_GLOBAL_CACHE_DIR=$WORKSPACE/.zig-cache

zig build jll \
    -Dtriple=${target} \
    -Doptimize=ReleaseSafe \
    --prefix ${prefix}

install_license LICENSE
"""

# Platforms
# All BinaryBuilder-supported platforms 
platforms = [
    # Linux glibc
    Platform("i686",    "linux"; libc="glibc"),
    Platform("x86_64",  "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv6l",  "linux"; libc="glibc", call_abi="eabihf"),
    Platform("armv7l",  "linux"; libc="glibc", call_abi="eabihf"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("riscv64", "linux"; libc="glibc"),

    # Linux musl
    Platform("i686",    "linux"; libc="musl"),
    Platform("x86_64",  "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv6l",  "linux"; libc="musl", call_abi="eabihf"),
    Platform("armv7l",  "linux"; libc="musl", call_abi="eabihf"),

    # macOS
    Platform("x86_64",  "macos"),
    Platform("aarch64", "macos"),

    # FreeBSD
    Platform("x86_64",  "freebsd"),
    Platform("aarch64", "freebsd"),

    # Windows
    Platform("i686",    "windows"),
    Platform("x86_64",  "windows"),
]

# Products
# Zig emits `libsie.{so,dylib}` on Unix and `sie.dll` on Windows (no `lib`
# prefix). BB matches the exact basename, so we list both candidates.
products = [
    LibraryProduct(["libsie", "sie"], :libsie_z),
]

# Dependencies
# libsie has no third-party runtime dependencies — only libc. The Zig
# toolchain is provided via the ArchiveSource above
dependencies = BinaryBuilder.AbstractDependency[]

# Build
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat   = "1.9",
    preferred_gcc_version = v"10",  # only used for the host-tool stage
)
