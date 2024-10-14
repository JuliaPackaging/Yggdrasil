# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Givaro"
version = v"4.2.0"

# Collection of sources required to complete build
sources = [
    AchiveSource("https://github.com/linbox-team/givaro/releases/download/v4.2.0/givaro-4.2.0.tar.gz", "73ef15ca34c6f1c9f61013d2bd7d4d547e3ace14"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/givaro

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p0 ${f}
done

./configure CCNAM=${CC} CPLUS_INCLUDE_PATH=$includedir --prefix=$prefix --build=${MACHTYPE} --host=${target}

# really ugly! but I see no other solution for now.
if [[ ${target} != aarch64-apple-darwin* ]]; then
#    patch -p0 < ${WORKSPACE}/srcdir/patches/libtool-aarch64-apple-darwin.hack
fi

make -j ${nproc}
make install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()                                                       
filter!(!Sys.iswindows, platforms)

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9")