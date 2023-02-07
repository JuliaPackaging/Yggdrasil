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
if [[ "${target}" == *-w64-mingw32* ]]; then    
    install -D -m 755 "target/${rust_target}/release/questdb_client.${dlext}" "${libdir}/c_questdb_client.${dlext}"
else
    install -D -m 755 "target/${rust_target}/release/libquestdb_client.${dlext}" "${libdir}/c_questdb_client.${dlext}"
fi

install -D -m 755 "${WORKSPACE}/srcdir/c-questdb-client/include/questdb/ilp/line_sender.h" "${includedir}/line_sender.h"


"""
#only macos
platforms = supported_platforms(exclude=Sys.islinux)
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [    
    LibraryProduct("c_questdb_client", :c_questdb_client)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers=[:c, :rust])