# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tmux"
# Upstream uses version numbers like 3.1, 3.1a, 3.1b, 3.1c, we convert the
# letter into the patch number
version = v"3.4.0"
# 3.3-rc is a Release Candidate, but for stable ones you'll need to remove the -rc
# tmux_tag = "$(version.major).$(version.minor)" * (version.patch > 0 ? Char('a' - 1 + version.patch) : "") * "-rc"
tmux_tag = "$(version.major).$(version.minor)" * (version.patch > 0 ? Char('a' - 1 + version.patch) : "")

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/tmux/tmux/releases/download/$(tmux_tag)/tmux-$(tmux_tag).tar.gz",
                  "551ab8dea0bf505c0ad6b7bb35ef567cdde0ccb84357df142c254f35a23e19aa"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tmux-*
# Needed for 3.4, already fixed on master
atomic_patch -p1 ../patches/byteorder.patch
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-TERM=screen --enable-utf8proc
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("tmux", :tmux)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libevent_jll"),
    Dependency("Ncurses_jll"),
    Dependency("utf8proc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build Trigger: 1
