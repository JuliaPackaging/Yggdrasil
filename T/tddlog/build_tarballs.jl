using BinaryBuilder, Pkg

name = "tddlog"
version = v"0.1.1"

sources = [
    GitSource("https://github.com/Tractables/tddlog.git",
              "bda693d57b21d0182bc710eef3fff7d38e7b96fb";
              tag="v$(version)"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/tddlog
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/jemalloc-windows.patch
cd bindings/c
# bindings/c is a cargo workspace of its own without a Cargo.lock: build with
# the dependency versions the crate's Cargo.lock pins.
cp -v ../../Cargo.lock .
if [[ "${target}" == *-musl* ]]; then
    # Rust's musl targets link the C runtime statically, which rules out a cdylib.
    export RUSTFLAGS="-C target-feature=-crt-static"
fi
# On Linux targets goatd's build script takes a g++ from PATH unless GOATD_CXX
# names the C++ compiler.
export GOATD_CXX="${CXX}"
cargo build --release
install -Dvm 755 target/${rust_target}/release/*tddlog_c.${dlext} -t "${libdir}"
install -Dvm 644 include/tddlog.h -t "${includedir}"
install_license ../../LICENSE ../../NOTICE ../../THIRD-PARTY.md
"""

platforms = expand_cxxstring_abis(supported_platforms())
# CompilerSupportLibraries_jll 1.0.5 has no riscv64 build, so the audit cannot resolve libgcc_s.
filter!(p -> arch(p) != "riscv64", platforms)
# Nor an aarch64 FreeBSD build.
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

products = [
    LibraryProduct(["libtddlog_c", "tddlog_c"], :libtddlog_c),
]

dependencies = [
    # libgcc_s and libstdc++; 1.0.5 is the version Julia 1.10 ships.
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
]

include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
# goatd's vendored C++20 code needs std::popcount and std::countr_zero (<bit>),
# which the default SDKs' libc++ headers lack; its runtime needs stop at 10.14,
# the oldest macOS Julia 1.10 supports on x86_64.
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="10.14")

# julia_compat: Tddlog.jl, the package this JLL is for, needs Julia 1.10.
# GCC: the oldest that compiles goatd's C++20 code.
# lock_microarchitecture: cc-rs passes the target's base -march (i686, armv6,
# armv7-a), which the compiler wrappers otherwise refuse.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10",
               compilers=[:c, :rust],
               preferred_gcc_version=v"10",
               lock_microarchitecture=false)
