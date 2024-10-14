# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Givaro"
version = v"4.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/linbox-team/givaro/releases/download/v$version/givaro-$version.tar.gz", "865e228812feca971dfb6e776a7bc7ac959cf63ebd52b4f05492730a46e1f189"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/givaro-4.2.0

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p0 ${f}
done

autoreconf
./configure CCNAM=${CC} CPLUS_INCLUDE_PATH=$includedir --prefix=$prefix --build=${MACHTYPE} --host=${target}

# really ugly! but I see no other solution for now.
# this patch modifies libtool so that it doesn't use the not-yet-implemented "-r" flag for the linker, replacing it by -dynamiclib
if [[ ${target} =~ aarch64-apple-darwin* ]]; then
    echo "Patching libtool so it doesn't use ld -r"
    patch -p0 < ${WORKSPACE}/srcdir/patches/libtool-aarch64-apple-darwin.hack
fi

make -j ${nproc}
make install

install_license Licence_CeCILL-B_V1-en.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [Platform("aarch64","macos"), Platform("x86_64","macos")]
# building on x86_64-linux fails with error "undefined reference to `memcpy@GLIBC_2.14'" when linking gmp

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgivaro", :libgivaro),
    FileProduct("include/givaro-config.h", :givaro_config_h)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.2.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")