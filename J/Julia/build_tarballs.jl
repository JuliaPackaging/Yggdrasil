using BinaryBuilder

name = "Julia"
version = v"1.4.1"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:armv7l; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:aarch64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:i686; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Windows(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Windows(:i686; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
]

sources = [
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/linux/aarch64/1.4/julia-1.4.1-linux-aarch64.tar.gz",
                  "788dc1e79344b52f65358ce4406dc5304bafd82c6af50bfa92a6ee5ea998e678"; unpack_target="aarch64-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/linux/armv7l/1.4/julia-1.4.1-linux-armv7l.tar.gz",
                  "bdcf24e0365f16092838daf7059bf5c0036bff9dc418511010e79249d9f71e96"; unpack_target="armv7l-linux-gnueabihf-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/linux/x64/1.4/julia-1.4.1-linux-x86_64.tar.gz",
                  "fd6d8cadaed678174c3caefb92207a3b0e8da9f926af6703fb4d1e4e4f50610a"; unpack_target="x86_64-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/linux/x86/1.4/julia-1.4.1-linux-i686.tar.gz",
                  "765e614b2754b20d50bae475dd9f3b794f445915084afa42523fd1b14e4c91fe"; unpack_target="i686-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/mac/x64/1.4/julia-1.4.1-mac64.tar.gz",
                  "78afd9c6769d645f7c30ad14dacadfd826cc5b1b3227c46fd7592ecde8af2fc3"; unpack_target="x86_64-apple-darwin14-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/winnt/x64/1.4/julia-1.4.1-win64.tar.gz",
                  "c4c1ae109f7eed5e9791d871b3e29003309d61ffa55a05cfd23184447ec8cfbe"; unpack_target="x86_64-w64-mingw32-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/winnt/x86/1.4/julia-1.4.1-win32.tar.gz",
                  "04d1abb1e28d643c6d049a4b241483ced155aebaf3eea8fb2d995299543645c5"; unpack_target="i686-w64-mingw32-libgfortran4-cxx11"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/freebsd/x64/1.4/julia-1.4.1-freebsd-x86_64.tar.gz",
                  "f7a6545953f8843201acec16ea66ba0d0ced8145439b6cebfcb893e9671cf7af"; unpack_target="x86_64-unknown-freebsd11.1"), 
]
script = raw"""
cp -rva ${WORKSPACE}/srcdir/${bb_full_target}/julia-*/* ${prefix}/
install_license /usr/share/licenses/MIT
"""

# The products that we will ensure are always built
products = [
    ExecutableProduct("julia", :julia),
    LibraryProduct("libjulia", :libjulia; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built/used
dependencies = [
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
