# BinaryBuilder.jl recipe for libsie_z_jll.
using BinaryBuilder, Pkg

#library
name      = "libsie_z"
version   = v"0.3.3"
repo      = "https://github.com/efollman/libsie-z.git"
tree_hash = "76034b20049e95da6a0380bc2d6c2634d227781c"

# zig tarball
# zig_version = "0.15.2"
#zig_sha256  = "02aa270f183da276e5b5920b1dac44a63f1a49e55050ebde3aecc9eb82f93239"
#zig_url     = "https://ziglang.org/download/$(zig_version)/zig-x86_64-linux-$(zig_version).tar.xz"

sources = [
    GitSource(repo, tree_hash),
]

# Runs inside the BinaryBuilder sandbox. `${target}` is the BB GNU triple,
# which `build.zig` translates to a Zig target via `-Dtriple=`.
script = raw"""
cd $WORKSPACE/srcdir/libsie-z*

zig build jll \
    -Dtriple=${target} \
    -Doptimize=ReleaseSafe \
    --prefix ${prefix}

install_license LICENSE
"""

# All BinaryBuilder-supported platforms
platforms = supported_platforms()

# Zig emits `libsie.{so,dylib}` on Unix and `sie.dll` on Windows. BB matches the exact basename, so we list both candidates.
products = [
    LibraryProduct(["libsie", "sie"], :libsie_z),
]

#waiting on zig_jll to have musl linux artifact available
dependencies = BinaryBuilder.AbstractDependency[
    HostBuildDependency(
        PackageSpec(name = "zig_jll", version = v"0.15.2+1");
        platforms = [Platform("x86_64", "linux"; libc = "glibc")],
    ),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat   = "1.9",
    preferred_gcc_version = v"10",  # only used for the host-tool stage
)
