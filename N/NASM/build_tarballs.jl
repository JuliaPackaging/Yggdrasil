# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NASM"
version_string = "3.02"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/netwide-assembler/nasm", "4a56d66ed9626d5a3ded5414c9d8b7f1a48ce065"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nasm*
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-zlib=${prefix}

# Fix broken <stdbool.h> detection
# (This is an autoconf problem. It is looking for macros, but C23 switched to using keywords.
#  Future autoconfs will fix this, I'm sure.)
# There are apparently two flavours for disabling a setting; the
# `#undef` might be in comments or not. Handle both.
sed -i -e 's+/\* #undef HAVE_STDBOOL_H \*/+#define HAVE_STDBOOL_H 1+' config/config.h
sed -i -e 's+/#undef HAVE_STDBOOL_H/+#define HAVE_STDBOOL_H 1+' config/config.h

make -j${nproc}

# Create fake manpages to make the installer happy
:> nasm.1
:> ndisasm.1

make install

# Uninstall the fake manpages
rm ${prefix}/share/man/man1/nasm.1
rm ${prefix}/share/man/man1/ndisasm.1

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("ndisasm", :ndisasm),
    ExecutableProduct("nasm", :nasm)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
