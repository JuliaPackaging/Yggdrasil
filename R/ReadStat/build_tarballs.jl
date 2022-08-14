# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ReadStat"
version = v"1.1.8"

sources = [
    GitSource("https://github.com/WizardMac/ReadStat.git",
              "f0b31497d69ec1b0585a73eeede3048a4ed15cbc"),
]

# Bash recipe for building across all platforms
script = raw"""
# Add `gettext` for `autogen.sh`
apk update
apk add gettext-dev

# GCC builds complain about string truncation, but we don't care
if [[ ${target} != *apple* ]] && [[ ${target} != *freebsd* ]]; then
    export CFLAGS="${CFLAGS} -Wno-stringop-truncation"
fi

# Windows doesn't search ${prefix}/include?
export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"

# Fix "Undefined symbols for architecture arm64: "_libiconv","
export LDFLAGS="-L${libdir}"

cd $WORKSPACE/srcdir/ReadStat/
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("readstat", :readstat),
    LibraryProduct("libreadstat", :libreadstat),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
