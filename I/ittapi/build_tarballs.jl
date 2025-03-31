# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ittapi"
version = v"3.25.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/intel/ittapi.git",
              "dec1d23ca65ab069d225dfe40dea14f455170959"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ittapi/
atomic_patch -p1 ../patches/0001-Add-non-exec-stack-annotation-only-for-ELF.patch
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DITT_API_IPT_SUPPORT=1
make -j${nproc}
ar -x bin/libittnotify.a
${CC} -shared ittnotify_static*.o ittptmark*.o -o libittnotify.${dlext}
install -Dvm 0755 libittnotify.${dlext} ${libdir}/libittnotify.${dlext}
install_license LICENSES/*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libittnotify", :libittnotify)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
