# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Git"
version = v"2.23.0"

# Collection of sources required to build Git
sources_unix = [
    "https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(version).tar.xz" =>
    "234fa05b6839e92dc300b2dd78c92ec9c0c8d439f65e1d430a7034f60af16067"
]

sources_w32 = [
    "https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-32-bit.tar.bz2" =>
    "c2e95e31b633c66845aae7ffd4cff8a8e3202137ae5954199551c09b164cd266"
]

sources_w64 = [
    "https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-64-bit.tar.bz2" =>
    "88076579c843edd1d048635b552ff4899818f9bdbeedf5e1e3cf8b5dc93129f5"
]

# Bash recipe for building across all Unices
script_unix = raw"""
cd $WORKSPACE/srcdir/git-*/

# We need a native "msgfmt" to cross-compile
apk add tcl gettext

# Git doesn't want to be cross-compiled, but we swear that we're not going to
# cross-compile
sed -i 's/cross_compiling=yes/cross_compiling=no/' configure

if [[ "${target}" == *-apple-* ]]; then
    LDFLAGS="-lgettextlib"
elif [[ ${target} == *-freebsd* ]]; then
    LDFLAGS="-L${prefix}/lib -lcharset"
fi

./configure --prefix=$prefix --host=$target \
    --with-curl \
    --with-expat \
    --with-openssl \
    --with-iconv=${prefix} \
    --with-libpcre2 \
    --with-zlib=${prefix} \
    CPPFLAGS="-I${prefix}/include" \
    LDFLAGS="${LDFLAGS}"
make -j${nproc}
make install INSTALL_SYMLINKS="yes, please"
"""

# Bash recipe for installing on Windows
script_win = raw"""
cd $WORKSPACE/srcdir/mingw*/
cp -r * ${prefix}
"""

# The products that we will ensure are always built
products = [
    ExecutableProduct("git", :git),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "LibCURL_jll",
    "Expat_jll",
    "OpenSSL_jll",
    "Gettext_jll",
    "Libiconv_jll",
    "PCRE2_jll",
    "Zlib_jll",
]

# Install first for win32, then win64.  This will accumulate files into `products` and also wrappers into the JLL package.
non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

# Get the list of platforms requested from the command line.  This should be the
# only argument not prefixed with "--".
requested_platforms = filter(arg -> !occursin(r"^--.*", arg), ARGS)
# This returns whether the builder for the given `platform` should be run.
function run_platform(platform)
    if isone(length(requested_platforms))
        # `requested_platforms` has only one element: the comma-separated list
        # of platform.  We'll run the platform only if it's in the list
        return platform in split(requested_platforms[1], ",")
    else
        # `requested_platforms` doesn't have only one element: if its length is
        # zero, no platform has been explicitely passed from the command line
        # and we we'll run all platforms, otherwise we don't know what to do, so
        # let's return false.
        return iszero(length(requested_platforms))
    end
end

if run_platform("i686-w64-mingw32")
    build_tarballs(non_reg_ARGS, name, version, sources_w32, script_win, [Windows(:i686)], products, [])
end
if run_platform("x86_64-w64-mingw32")
    build_tarballs(non_reg_ARGS, name, version, sources_w64, script_win, [Windows(:x86_64)], products, [])
end
# Then for everything else.  This is the only one that we try to register, and this is the step that will open a PR against General
platforms = filter!(p -> !isa(p, Windows), supported_platforms())
if any(run_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources_unix, script_unix, platforms, products, dependencies)
end

