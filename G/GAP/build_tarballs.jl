# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "GAP"
version = v"4.11.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gap-system/gap.git", "a20c8f40883c8656a240317d732229dbe7c3b5ab"),
#    ArchiveSource("https://github.com/gap-system/gap/releases/download/v$(version)/gap-$(version)-core.tar.bz2",
#                  "6637f66409bc91af21eaa38368153270b71b13b55b75cc1550ed867c629901d1"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gap*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/configure.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/Makefile.patch

# run autogen.sh if compiling from it source and/or if configure was patched
./autogen.sh

# compile GAP
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-gmp=${prefix} \
    --with-readline=${prefix} \
    --with-zlib=${prefix} \
    --with-gc=julia \
    --with-julia
make -j${nproc}

# install GAP binaries
make install-bin install-headers install-libgap

# get rid of the wrapper shell script, which is useless for us
mv ${WORKSPACE}/destdir/bin/gap.real ${WORKSPACE}/destdir/bin/gap

# install sysinfo.gap but patch out
mkdir -p ${WORKSPACE}/destdir/share/gap/
sed -e 's;$PWD;@GAPROOT@;g' sysinfo.gap > ${WORKSPACE}/destdir/share/gap/sysinfo.gap

# We deliberately do NOT install the GAP library, documentation, etc. because
# they are identical across all platforms; instead, we use another platform
# independent artifact to ship them to the user.
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# we only care about 64bit builds
filter!(p -> nbits(p) == 64, platforms)

# Windows is not supported
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("gap", :gap),
    LibraryProduct("libgap", :libgap),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("Readline_jll"),
    Dependency("Zlib_jll"),

    # GAP tries hard to produce a binary that works in all Julia versions,
    # regardless of which version of Julia it was compiled again; so the
    # version restriction below could be dropped or changed if necessary
    BuildDependency(PackageSpec(name="libjulia_jll", version=v"1.4.2")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
