# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Increment to rebuild without version bump
# Build count: 1
name = "Metal_Shader_Converter"
version = v"1.1"

# Collection of sources required to complete build
sources = [
    DirectorySource("bundled"),
    FileSource("https://download.developer.apple.com/Developer_Tools/Metal_shader_converter_1.1/Metal_Shader_Converter_1.1.pkg",
               "83205d3198534560268ecb3efe44cf72bebd5cfde5d20f7028ac22fdbfded90e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license LICENSE

apk add p7zip
7z x Metal_Shader_Converter_1.1.pkg
7z x Payload\~

mv usr/local/lib usr/local/include $prefix
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; )
]

# The products that we will ensure are always built
products = [
    # we're not allowed to redistribute the executable
    LibraryProduct("libmetalirconverter", :libmetalirconverter),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

