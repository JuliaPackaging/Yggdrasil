using BinaryBuilder

name = "VIC5"
version = v"0.1.2"

# Collection of sources required to build
sources = [
    GitSource("https://github.com/CUG-hydro/VIC5.c.git",
    "4d9d72a6bcc573cc19144493dc09898054e72d18"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/VIC5.c/vic/drivers/classic

# mkdir -p ${prefix}/bin ${prefix}/lib

make CC=${CC} -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/VIC5.c/LICENSE.txt

## debug
echo $bindir $libdir
ls ${prefix}/bin
ls $bindir
ls $libdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libvic5_classic", :libvic5_classic),
    ExecutableProduct("vic_classic", :vic5_classic),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
