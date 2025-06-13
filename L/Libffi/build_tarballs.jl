using BinaryBuilder

name = "Libffi"
upstream_version = "3.4.7"
version = VersionNumber(upstream_version)

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://github.com/libffi/libffi/releases/download/v$(upstream_version)/libffi-$(upstream_version).tar.gz",
                  "138607dee268bdecf374adf9144c00e839e38541f75f24a1fcf18b78fda48b2d"),
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
