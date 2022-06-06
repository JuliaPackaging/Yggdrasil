using BinaryBuilder

name = "pigz"
version = v"2.7"

# Collection of sources required to build pigz
sources = [
    ArchiveSource("https://zlib.net/pigz/pigz-$(version.major).$(version.minor).tar.gz",
                  "b4c9e60344a08d5db37ca7ad00a5b2c76ccb9556354b722d56d55ca7e8b1c707"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/pigz-*

export CPPFLAGS="-I${includedir}"
if [[ "${target}" == *-freebsd* ]]; then
    # Without this, `__XSI_VISIBLE`, `S_IFMT`, `S_IFREG`, `S_IFMT`,
    # `S_IFREG`, `S_IFIFO`, and `S_IFDIR` are all undefined
    CPPFLAGS="${CPPFLAGS} -D_XOPEN_SOURCE=700"
fi
make -j${nproc} CC=${CC}

# Install
mkdir -p ${bindir}
for bin in pigz unpigz; do
    cp "${bin}" "${bindir}/${bin}${exeext}"
done

# License is embedded at the end of the README
install_license README
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
