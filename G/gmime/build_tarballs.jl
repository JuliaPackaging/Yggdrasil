# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gmime"
version = v"3.2.15"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/jstedfast/gmime/releases/download/$(version)/gmime-$(version).tar.xz", 
                  "84cd2a481a27970ec39b5c95f72db026722904a2ccf3fdbd57b280cf2d02b5c4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gmime*
echo '#define ICONV_ISO_INT_FORMAT "iso-%u-%u"' > iconv-detect.h
echo '#define ICONV_ISO_STR_FORMAT "iso-%u-%s"' >> iconv-detect.h
echo '#define ICONV_SHIFT_JIS "shift-jis"' >> iconv-detect.h
echo '#define ICONV_10646 "UCS-4BE"' >> iconv-detect.h

if [[ "${target}" == *-apple-* ]]; then
   # Help the linker prefer our libiconv over system's libiconv.
   export LDFLAGS="-L${libdir}"
fi

./configure --prefix=${prefix} \
            --build=${MACHTYPE} \
            --host=${target} \
            --enable-static=no \
            --with-libiconv=gnu \
            ac_cv_have_iconv_detect_h=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> Sys.isfreebsd(p) && arch(p) == "aarch64")


# The products that we will ensure are always built
products = [
    LibraryProduct(["libgmime-3", "libgmime-3.0"], :libgmime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"); compat="2.68.1")
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
