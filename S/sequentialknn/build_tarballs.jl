# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "sequentialknn"
version = v"0.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/cgeoga/sequentialknn",
        "ef59da866a14ff5a53e27295cfd6f8d9ca2999c3"),
]

# Bash recipe for building across all platforms.
#
# CG: this is kind of gross looking, but I just had a lot of issues with the
# ${libext} and stuff not working. And on windows, rust doesn't put lib in front
# of the library name. So there is some manual tinkering here just to make all
# the file names exist as expected.
script = raw"""
cd $WORKSPACE/srcdir/sequentialknn/
cargo build --release
case "${target}" in
    *apple-darwin*)
        ext=dylib
        ;;
    *linux*)
        ext=so
        ;;
    *w64*)
        ext=dll
        ;;
esac
outlibname="libsequentialknn.${ext}"
install -Dvm 0644 "target/${rust_target}/release/${libname}" "${libdir}/${outlibname}"
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
products = [LibraryProduct("libsequentialknn", :libsequentialknn)]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[Dependency("Libiconv_jll")]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)
