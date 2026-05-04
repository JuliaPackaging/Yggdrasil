# BinaryBuilder.jl recipe for libsie_z_jll.
using BinaryBuilder, Pkg

#library
name      = "libsie_z"
version   = v"0.3.3"
repo      = "https://github.com/efollman/libsie-z.git"
tree_hash = "76034b20049e95da6a0380bc2d6c2634d227781c"

zig_jll_version = v"0.15.2+1"

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
        PackageSpec(name = "zig_jll", version = zig_jll_version)
    ),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat   = "1.9",
)
