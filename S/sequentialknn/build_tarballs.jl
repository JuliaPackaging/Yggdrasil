# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "sequentialknn"
version = v"0.2"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/cgeoga/sequentialknn",
        "31dec6fc265e5606e7009d972159f966484de066"),
]

script = raw"""
cd $WORKSPACE/srcdir/sequentialknn/
cargo build --release
install -Dvm 755 "target/${rust_target}/release"/*sequentialknn.${dlext} -t "${libdir}"
install_license LICENSE
"""

# The rust support is reasonably narrow. But I think even just supporting these
# platforms will cover a significant majority of users.
platforms = [
             Platform("aarch64", "macos"),
             Platform("x86_64",  "macos"),
             Platform("x86_64",  "windows"),
             Platform("x86_64",  "linux", libc="glibc")
            ]

# The products that we will ensure are always built
products = [LibraryProduct(["libsequentialknn", "sequentialknn"], :libsequentialknn)]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[Dependency("Libiconv_jll")]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)
