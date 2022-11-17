# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "P11Kit"
version = v"0.24.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/p11-glue/p11-kit/releases/download/$(version)/p11-kit-$(version).tar.xz", "d8be783efd5cd4ae534cee4132338e3f40f182c3205d23b200094ec85faaaef8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
meson --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release p11-kit-*

# Meson beautifully forces thin archives, without checking whether the dynamic linker
# actually supports them: <https://github.com/mesonbuild/meson/issues/10823>.  Let's remove
# the (deprecated...) `T` option to `ar`
sed -i.bak 's/csrDT/csrD/' build.ninja

ninja -j${nproc}
ninja install
install_license p11-kit-*/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    # p11-kit-client.so is not built on Windows, so we temporarily disable it
    # LibraryProduct("p11-kit-client", :libp11kitclient, "lib/pkcs11"),
    LibraryProduct("libp11-kit", :libp11kit),
    ExecutableProduct("p11-kit", :p11kit)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
