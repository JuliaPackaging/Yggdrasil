# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "ripgrep"
version = v"13.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/BurntSushi/ripgrep/archive/$(version).tar.gz",
                  "0fb17aaf285b3eee8ddab17b833af1e190d73de317ff9648751ab0660d763ed2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ripgrep-*/
cargo build --release --features 'pcre2'
mkdir -p "${bindir}"
cp "target/${rust_target}/release/rg${exeext}" "${bindir}/."
install_license COPYING LICENSE-MIT UNLICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# All Musl-based ARM platforms fail with this error:
#
#     = note: /workspace/srcdir/ripgrep-13.0.0/target/aarch64-unknown-linux-musl/release/deps/libpcre2_sys-1c7f8ac14084107f.rlib(pcre2_jit_compile.o): In function `sljit_generate_code':
#             /opt/x86_64-linux-musl/registry/src/github.com-1ecc6299db9ec823/pcre2-sys-0.2.5/pcre2/src/sljit/sljitExecAllocator.c:178: undefined reference to `__clear_cache'
#             collect2: error: ld returned 1 exit status
filter!(p -> libc(p) != "musl" || proc_family(p) != "arm", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("rg", :rg),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)
