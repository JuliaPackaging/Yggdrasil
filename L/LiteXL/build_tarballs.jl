 using BinaryBuilder, Pkg

name = "LiteXL"
version = v"1.16.12"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/lite-xl/lite-xl/archive/refs/tags/v$(version).tar.gz",
                  "83760c880d83666d5043723b61db0964147184e2c91dba7285ec6f2075f6e602")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lite-xl-*
meson --cross-file=${MESON_TARGET_TOOLCHAIN} build
cd build
ninja 
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("lite", :lite),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf")),
    Dependency(PackageSpec(name="FreeType2_jll", uuid="d7e528f0-a631-5988-bf34-fe36492bcfd7")),
    Dependency(PackageSpec(name="PCRE2_jll", uuid="efcefdf7-47ab-520b-bdef-62a2eaa19f15")),
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid = "c4d99508-4286-5418-9131-c86396af500b")),
    Dependency(PackageSpec(name="X11_jll", uuid = "546b0b6d-9ca3-5ba2-8705-1bc1841d8479")),
    Dependency(PackageSpec(name="Lua_jll", uuid = "a4086b1d-a96a-5d6b-8e4f-2030e6f25ba6")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
