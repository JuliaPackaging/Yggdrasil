# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "startin"
version = v"0.4.9"

sources = [
    ArchiveSource(
        "https://github.com/evetion/startin/archive/c-interface.zip",  # PR branch
        "d3a987e9ab20ee3504c8c79f0940ce22527e23ed8b029e8d12136831fe996c63"
    )
]

script = raw"""
cd $WORKSPACE/srcdir/startin-c-interface/
if [[ "${target}" == *-darwin* ]] || [[ "${target}" == *-freebsd* ]]; then
    # Fix linker for BSD platforms
    sed -i "s/${rust_target}-gcc/${target}-gcc/" "${CARGO_HOME}/config"
fi
if [[ "${target}" == *-w64-mingw32* ]]; then
    # Fix from https://github.com/rust-lang/rust/issues/32859#issuecomment-573423629, see https://github.com/rust-lang/rust/issues/47048
    cp -f /opt/${target}/${target}/sys-root/lib/{,dll}crt2.o `rustc --print sysroot`/lib/rustlib/${rust_target}/lib
fi
cargo build --features c_api --release -j${nproc}
mkdir ${libdir}
if [[ "${target}" == *-w64-mingw32* ]]; then
    # Windows generates .dlls without the lib prefix
    cp target/${rust_target}/release/startin.dll ${libdir}/libstartin.dll
else
    cp target/${rust_target}/release/libstartin.${dlext} ${libdir}/libstartin.${dlext}
fi
"""

# musl platforms are failing, as is win32
platforms = [
    Platform("x86_64", "freebsd"),
    Platform("aarch64", "linux"; libc="glibc"),
    # Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="glibc"),
    # Platform("armv7l", "linux"; libc="musl"),
    Platform("i686", "linux"; libc="glibc"),
    # Platform("i686", "linux"; libc="musl"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    # Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    # Platform("i686", "windows"),  # linking error
    Platform("x86_64", "windows"),
]

products = [
    LibraryProduct("libstartin", :libstartin),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust])
