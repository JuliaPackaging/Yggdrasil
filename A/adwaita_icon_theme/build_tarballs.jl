# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "adwaita_icon_theme"
version = v"3.33.93" # new patch version to build for all platforms

# Collection of sources required to build adwaita-icon-theme
sources = [
    ArchiveSource("https://github.com/JuliaBinaryWrappers/adwaita_icon_theme_jll.jl/releases/download/adwaita_icon_theme-v3.33.92+4/adwaita_icon_theme.v3.33.92.any.tar.gz",
    "f50f3c85710f7dfbd6959bfaa6cc3a940195cd09dadddefb3b5ae9a2f97adad3"),
]

# Bash recipe for building across all platforms
script = raw"""
rsync -a $WORKSPACE/srcdir/share ${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    FileProduct("share/icons", :adwaita_icons_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("hicolor_icon_theme_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
