# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libgmime"
version = v"3.2.15"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jstedfast/gmime.git", "76aee730fedc41dc09e1819d85bf0800bdbc0a2d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd gmime/
apk add gtk-doc

echo '#define ICONV_ISO_INT_FORMAT "iso-%u-%u"' > iconv-detect.h
echo '#define ICONV_ISO_STR_FORMAT "iso-%u-%s"' >> iconv-detect.h
echo '#define ICONV_SHIFT_JIS "shift-jis"' >> iconv-detect.h
echo '#define ICONV_10646 "UCS-4BE"' >> iconv-detect.h

export LDFLAGS="$LDFLAGS -liconv"
CMAKE_EXE_LINKER_FLAGS="-Wl,--copy-dt-needed-entries"
export CMAKE_EXE_LINKER_FLAGS

./autogen.sh 
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libgmime", :libgmime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"))
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
