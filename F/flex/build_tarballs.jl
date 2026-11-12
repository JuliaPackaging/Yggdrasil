# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "flex"
version = v"2.6.4"
ygg_version = v"2.6.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/westes/flex.git",
              "ab49343b08c933e32de8de78132649f9560a3727"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/flex*

atomic_patch -p1 ../patches/scanner-segfault.patch

apk add gettext gettext-dev help2man texinfo

# For macOS, allow undefined symbols in libfl (yylex is provided by user code)
if [[ "${target}" == *-apple-* ]]; then
    export LDFLAGS="-Wl,-undefined,dynamic_lookup"
fi

./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --enable-shared ac_cv_func_reallocarray=no
make -j${nproc}
cd src && make install
install -Dvm 0755 ${bindir}/flex ${bindir}/flex++
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;exclude=Sys.iswindows, experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("flex", :flex),
    ExecutableProduct("flex++", :flexpp),
    LibraryProduct("libfl", :libfl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
