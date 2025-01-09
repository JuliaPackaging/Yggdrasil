# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

name = "PCRE2"
version_string = "10.44"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PCRE2Project/pcre2", "6ae58beca071f13ccfed31d03b3f479ab520639b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pcre2*

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

./autogen.sh

# Update configure scripts
update_configure_scripts

# Force optimization
export CFLAGS="${CFLAGS} -O3"

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
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

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll",
                                uuid="4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version=llvm_version);
                    platforms=filter(p -> sanitize(p)=="memory", platforms)),

]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_llvm_version=llvm_version)

# Build trigger: 1
