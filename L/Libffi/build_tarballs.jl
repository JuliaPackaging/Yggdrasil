using BinaryBuilder

name = "Libffi"
upstream_version = "3.4.6"
version = VersionNumber(upstream_version)

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://github.com/libffi/libffi/releases/download/v$(upstream_version)/libffi-$(upstream_version).tar.gz",
                  "b0dea9df23c863a7a50e825440f3ebffabd65df1497108e5d437747843895a4e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libffi-*/
update_configure_scripts
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-static \
    --enable-shared \
    --disable-multi-os-directory
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libffi", :libffi)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")

# Build trigger: 1
