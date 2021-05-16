using BinaryBuilder

# Collection of sources required to build Libiconv
name = "Libiconv"
version = v"1.16.1" # <-- this is a lie, we're building v1.16, but we need to bump version to build for julia v1.6

sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$(version.major).$(version.minor).tar.gz",
               "e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"),
]

# Bash recipe for building across all platforms
script = "VERSION=$(version.major).$(version.minor)\n" * raw"""
cd $WORKSPACE/srcdir/libiconv-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install

# Add pkg-config file
mkdir -p "${prefix}/lib/pkgconfig"
cat << EOF > "${prefix}/lib/pkgconfig/iconv.pc"
prefix=${prefix}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/$(basename ${libdir})
sharedlibdir=\${libdir}
includedir=\${includedir}

Name: iconv
Description: libiconv
URL: https://www.gnu.org/software/libiconv/
Version: ${VERSION}

Requires:
Libs: -L\${libdir} -liconv
Cflags: -I\${includedir}
EOF
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcharset", :libcharset),
    LibraryProduct("libiconv", :libiconv),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
