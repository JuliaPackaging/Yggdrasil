using BinaryBuilder

name = "LibUnwind"
version = v"1.7.2"

# Collection of sources required to build libunwind
sources = [
    ArchiveSource("https://github.com/libunwind/libunwind/releases/download/v$(version)/libunwind-$(version).tar.gz",
                  "a18a6a24307443a8ace7a8acc2ce79fbbe6826cd0edf98d6326d0225d6a5d6e6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libunwind*/

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

export CFLAGS="-DPI -fPIC"
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --libdir=${libdir} \
    --enable-minidebuginfo \
    --enable-zlibdebuginfo \
    --disable-tests \
    --disable-conservative-checks
make -j${nproc}
make install

# Shoe-horn liblzma.a into libunwind.a
mkdir -p unpacked/{liblzma,libunwind}
(cd unpacked/liblzma; ar -x ${prefix}/lib/liblzma.a)
(cd unpacked/libunwind; ar -x ${prefix}/lib/libunwind.a)
rm -f ${prefix}/lib/libunwind.a
ar -qc ${prefix}/lib/libunwind.a unpacked/**/*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  libunwind is only used
# on Linux or FreeBSD (e.g. ELF systems)
platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libunwind", :libunwind),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("XZ_jll"),
    Dependency("Zlib_jll"),
    BuildDependency("LLVMCompilerRT_jll",
                    platforms = [Platform("x86_64", "linux"; sanitize="memory")]),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.7", preferred_gcc_version=v"5")
