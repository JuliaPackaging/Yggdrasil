using BinaryBuilder

# Collection of sources required to build Gettext
name = "FlexLexer"
version = v"2.6.4"

sources = [
            FileSource("https://raw.githubusercontent.com/westes/flex/master/src/FlexLexer.h",
                       "ee9859d6b3027ed565f98f42744e438ab31b2cd2e9f797ddf870029ca2021686"),
            FileSource("https://raw.githubusercontent.com/westes/flex/master/COPYING",
                       "97fd685958d93be7f8dab939bb8161dbd6afb0718c63bfc337c24321aea44273"),
                   ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/
install_license ${WORKSPACE}/srcdir/COPYING

mkdir -p ${prefix}/include
mv FlexLexer.h ${prefix}/include
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
                FileProduct("include/FlexLexer.h", :FlexLexer),
                ]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
                          ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
