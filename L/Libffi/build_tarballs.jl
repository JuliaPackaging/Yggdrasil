using BinaryBuilder

name = "Libffi"
version = v"3.2.1"


# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://sourceware.org/pub/libffi/libffi-$(version).tar.gz",
                  "d06ebb8e1d9a22d19e38d63fdb83954253f39bedc5d46232a05645685722ca37"),
    DirectorySource("./bundled"),
]

version = v"3.2.2" # <-- this is a lie, we need to bump the version to require julia v1.6

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libffi-*/
atomic_patch -p1 ../patches/0001-libdir-no-touchy.patch

# Required on aarch64-apple-darwin to build with newer versions of LLVM. See:
# - https://github.com/llvm/llvm-project/issues/72802
# - Similar issue: https://github.com/libffi/libffi/issues/807
# - In Julia: https://github.com/JuliaLang/julia/pull/54634
if [[ ${target} == aarch64-apple-* ]]; then
    atomic_patch -p1 ../patches/0002-aarch64-llvm18.patch
fi

update_configure_scripts
autoreconf -f -i
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --enable-shared
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libffi", :libffi)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
