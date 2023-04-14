using BinaryBuilder

name = "file"

# NOTE: the cross-compilation story of `file` is kind of broken
# and requires a two-step build; we dodge this by providing `file`
# in the rootfs right now, but this locks us to exactly this version.
version = v"5.41"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/file/file.git",
              "504206e53a89fd6eed71aeaf878aa3512418eab1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/file/

autoreconf -i -f
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install

install_license COPYING
"""

# Disable windows for now, as that requires `libgnurx`.
platforms = filter(!Sys.iswindows, supported_platforms())
# Disable i686-linux-musl because we end up in dynamic linker hell
platforms = filter(p -> !(libc(p) == "musl" && arch(p) == "i686"), platforms)

products = [
    ExecutableProduct("file", :file)
]
dependencies = [
    Dependency("Bzip2_jll"),
    Dependency("XZ_jll"),
    Dependency("Zlib_jll"),
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
