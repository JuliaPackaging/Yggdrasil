# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CRlibm"
version = v"1.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaIntervals/crlibm.git", "074c45a6103fa79868c8981f28f767f339531184"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/crlibm*/

autoreconf -fi
update_configure_scripts 
export CFLAGS="-fPIC -ffp-contract=off"
# The double-extended `log` sets the x87 control word to 53-bit precision and
# does not restore the caller's value, which changes the results of other x87 code.
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-double-extended
make -C scs_lib
make -j${nproc} libcrlibm.a
mkdir -p ${libdir}
cc -L. -shared -o ${libdir}/libcrlibm.${dlext} *.o scs_lib/*.o
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcrlibm", :libcrlibm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
