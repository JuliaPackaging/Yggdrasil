using BinaryBuilder

name = "ChibiScheme"
version = v"0.10"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/ashinn/chibi-scheme.git",
              "05eb4ebd357e2bf2fe5aa7da13b0422ce20ddf7f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/chibi-scheme

apk add chibi-scheme

make \
    PREFIX="${prefix}" \
    CC="${CC_BUILD}" \
    AR="${AR_BUILD}" \
    LD="${LD_BUILD}" \
    CFLAGS="${CFLAGS}" \
    CPPFLAGS="${CPPFLAGS}" \
    LDFLAGS="${LDFLAGS}" \
    RANLIB="${RANLIB_BUILD}" \
    CHIBI=`which chibi-scheme` \
    CHIBI_FFI=`which chibi-ffi` \
    CHIBI_DOC=`which chibi-doc` \
    SNOW_CHIBI=`which snow-chibi` \
    SO=".${dlext}" \
    EXE="${exeext}" \
    CLIBFLAGS="-fPIC" \
    CLINKFLAGS="-shared" \
    STATICFLAGS="-static -DSEXP_USE_DL=0" \
    LIBCHIBI_FLAGS=" " \
    install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libchibi-scheme", :libchibischeme),
    FileProduct("share/chibi/init-7.scm", :init_7_scm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
