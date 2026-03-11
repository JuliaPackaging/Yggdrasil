include(joinpath("..", "common.jl"))

name = "Cairo_NoGPL"

# Ensure LZO is not present in the build environment — meson auto-detects it,
# so its mere presence would cause Cairo to link against GPL code.
script = raw"""
if [ -f "${includedir}/lzo/lzoconf.h" ]; then
    echo "ERROR: LZO found in build environment, but this is a nogpl build!" >&2
    exit 1
fi
""" * script

# Dependencies: common set without LZO (which is GPL-licensed).
# LZO is auto-detected by Cairo's meson build system; if absent, Cairo builds without it.
dependencies = copy(common_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
