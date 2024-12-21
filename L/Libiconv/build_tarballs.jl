using BinaryBuilder

# Collection of sources required to build Libiconv
name = "Libiconv"
version_string = "1.17"
version = VersionNumber(version_string)

sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$(version_string).tar.gz",
               "8f74213b56238c85a50a5329f77e06198771e70dd9a739779f4c02f65d971313"),
]

# Bash recipe for building across all platforms
script = "VERSION=$(version.major).$(version.minor)\n" * raw"""
cd $WORKSPACE/srcdir/libiconv-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static --enable-extra-encodings
make -j${nproc}
make install

# Add pkg-config file
mkdir -p "${prefix}/lib/pkgconfig"
cat << EOF > "${prefix}/lib/pkgconfig/iconv.pc"
prefix=\${pcfiledir}/../..
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
platforms = supported_platforms()

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
