# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "grep"
version = v"3.12.0"

# Collection of sources required to complete build
sources = [
    # ArchiveSource("https://ftp.gnu.org/gnu/grep/grep-$(version.major).$(version.minor).tar.xz",
    #               "2649b27c0e90e632eadcd757be06c6e9a4f48d941de51e7c0f83ff76408a07b9"),
    GitSource("https://git.savannah.gnu.org/git/grep.git", "3f8c09ec197a2ced82855f9ecd2cbc83874379ab"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/grep*
apk add gettext texinfo
./bootstrap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("grep", :grep)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libiconv_jll"; compat="1.18.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
