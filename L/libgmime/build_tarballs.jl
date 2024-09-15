# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gmime"
version = v"3.2.15"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/jstedfast/gmime/releases/download/$(version)/gmime-$(version).tar.xz", "84cd2a481a27970ec39b5c95f72db026722904a2ccf3fdbd57b280cf2d02b5c4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gmime*
echo '#define ICONV_ISO_INT_FORMAT "iso-%u-%u"' > iconv-detect.h
echo '#define ICONV_ISO_STR_FORMAT "iso-%u-%s"' >> iconv-detect.h
echo '#define ICONV_SHIFT_JIS "shift-jis"' >> iconv-detect.h
echo '#define ICONV_10646 "UCS-4BE"' >> iconv-detect.h

export LDFLAGS="-liconv"
export CMAKE_EXE_LINKER_FLAGS="-Wl,--copy-dt-needed-entries"

./configure --prefix=${prefix} \
            --build=${MACHTYPE} \
            --host=${target} \
            ac_cv_have_iconv_detect_h=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=[Platform("aarch64", "FreeBSD")])


# The products that we will ensure are always built
products = [
    LibraryProduct(["libgmime-3", "libgmime-3.0"], :libgmime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"); compat="2.68.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
