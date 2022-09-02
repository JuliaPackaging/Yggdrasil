# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "PCRE2"
version = v"10.40"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$(version.major).$(version.minor)/pcre2-$(version.major).$(version.minor).tar.gz",
                  "ded42661cab30ada2e72ebff9e725e745b4b16ce831993635136f2ef86177724"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pcre2-*/

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

# Update configure scripts
update_configure_scripts

# Force optimization
export CFLAGS="${CFLAGS} -O3"

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --disable-static \
    --enable-jit \
    --enable-pcre2-16 \
    --enable-pcre2-32

make -j${nproc}
make install

# On windows we need libcpre2-8.dll as well
if [[ ${target} == *mingw* ]]; then
    ln -s libpcre2-8-0.dll  ${libdir}/libpcre2-8.dll
    ln -s libpcre2-16-0.dll ${libdir}/libpcre2-16.dll
    ln -s libpcre2-32-0.dll ${libdir}/libpcre2-32.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libpcre2-8", :libpcre2_8),
    LibraryProduct("libpcre2-16", :libpcre2_16),
    LibraryProduct("libpcre2-32", :libpcre2_32)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("LLVMCompilerRT_jll",platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9")
