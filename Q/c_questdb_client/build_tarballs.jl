using BinaryBuilder
using BinaryBuilderBase

name = "c_questdb_client"
version = v"2.1.3"

sources = [    
    GitSource("https://github.com/questdb/c-questdb-client", "ad3776efb057d09a86a83e15c0f39ae40d75485b")
]


# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/c-questdb-client/questdb-rs-ffi
cargo build --release
install -D -m 755 "target/${rust_target}/release/"*questdb_client."${dlext}" "${libdir}/libquestdb_client.${dlext}"
install -D -m 755 "${WORKSPACE}/srcdir/c-questdb-client/include/questdb/ilp/line_sender.h" "${includedir}/line_sender.h"
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# The dependency `ring` can't be compiled for PowerPC
filter!(p -> arch(p) != "powerpc64le", platforms)
# Can't generate the cdylib for Musl platforms
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
products = [    
    LibraryProduct("libquestdb_client", :libquestdb_client)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)
