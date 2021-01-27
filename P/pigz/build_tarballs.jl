using BinaryBuilder

name = "pigz"
version = v"2.5"

# Collection of sources required to build pigz
sources = [
    ArchiveSource("https://zlib.net/pigz/pigz-2.5.tar.gz",
                  "a006645702caaecace633a89eb5c371482b44a48d04f34e0058e2b85d75d4c36"),
]

# Bash recipe for building across all platforms
script = raw"""
# License is embedded at the end of the README
install_license ${WORKSPACE}/srcdir/pigz-*/README

cd ${WORKSPACE}/srcdir/pigz-*
export CPPFLAGS="-I${includedir}"
make -j${nproc}

# Install
mkdir -p ${bindir}
for bin in pigz unpigz; do
    cp "${bin}" "${bindir}/${exe}${exeext}"
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("pigz", :pigz),
    ExecutableProduct("unpigz", :unpigz),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
