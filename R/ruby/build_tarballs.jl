# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ruby"
version = v"2.7.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://cache.ruby-lang.org/pub/ruby/$(version.major).$(version.minor)/ruby-$(version).tar.gz",
        "d418483bdd0000576c1370571121a6eb24582116db0b7bb2005e90e250eae418",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ruby-*/
# otherwise readline and therefore ruby is held back
apk del python
# living on the edge...
sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories
apk update
# these return an error code, but work anyways ¯\_(ツ)_/¯
apk upgrade --update-cache --available --latest || true
apk add ruby-full || true
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-baseruby=/usr/bin/ruby --enable-shared
make -j${nproc}
make install
${bindir}/ruby -e 'puts $:' | sed "s:${prefix}/::g" > ${prefix}/RUBYLIB
for bin in $(grep -rl "${bindir}/ruby" ${bindir})
do
    sed -i "s:${bindir}/ruby:/usr/bin/env ruby:" ${bin}
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# Unfortunately Windows and Mac don't seem to cross-compile out of the box.
# It also seems like some of the libraries don't support case-insensitive file systems,
# so this might be a problem when trying to get those to work.
platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())
# TODO: fix armv7l musl. Probably an upstream issue though
filter!(!=(Platform("armv7l", "linux"; libc="musl")), platforms)
# Remove "experimental" architecture
filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libruby", :libruby),
    ExecutableProduct("ruby", :ruby),
    # These are actually ruby scripts
    ExecutableProduct("bundle", :bundle),
    ExecutableProduct("bundler", :bundler),
    ExecutableProduct("erb", :erb),
    ExecutableProduct("gem", :gem),
    ExecutableProduct("irb", :irb),
    ExecutableProduct("racc", :racc),
    ExecutableProduct("racc2y", :racc2y),
    ExecutableProduct("rake", :rake),
    ExecutableProduct("rdoc", :rdoc),
    ExecutableProduct("ri", :ri),
    # these are all subdirs of ${prefix} that need to be in the env var RUBYLIB for ruby to
    # work properly
    FileProduct("RUBYLIB", :RUBYLIB),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libiconv_jll"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    Dependency("Readline_jll"),
    Dependency("Zlib_jll"),
    Dependency("Gdbm_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
