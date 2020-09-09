using BinaryBuilder

name = "Julia"
version = v"1.3.0"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    FreeBSD(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:armv7l; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:aarch64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:i686; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Windows(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    #Windows(:i686; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
]

sources = [
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/aarch64/$(version.major).$(version.minor)/julia-$(version)-linux-aarch64.tar.gz",
                  "8557c86cb4f65e8d8c2b1da376e759548cb35942a63820a6d20bc1448c45ec1b"; unpack_target="aarch64-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/armv7l/$(version.major).$(version.minor)/julia-$(version)-linux-armv7l.tar.gz",
                  "7739a318f371250faf10befd5636008fbb84992cc90ee88b3a753b1ad408ad7c"; unpack_target="armv7l-linux-gnueabihf-libgfortran4-cxx11"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/x64/$(version.major).$(version.minor)/julia-$(version)-linux-x86_64.tar.gz",
                  "9ec9e8076f65bef9ba1fb3c58037743c5abb3b53d845b827e44a37e7bcacffe8"; unpack_target="x86_64-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/x86/$(version.major).$(version.minor)/julia-$(version)-linux-i686.tar.gz",
                  "e43339e72b2e71f8df343e6f542bf3a48cbbf7e9c135b076d5d651d9153615c9"; unpack_target="i686-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("https://github.com/Gnimuc/JuliaBuilder/releases/download/v$(version)/julia-$(version)-x86_64-apple-darwin14.tar.gz",
                  "f2e5359f03314656c06e2a0a28a497f62e78f027dbe7f5155a5710b4914439b1"; unpack_target="x86_64-apple-darwin14-libgfortran4-cxx11"),
    ArchiveSource("https://github.com/Gnimuc/JuliaBuilder/releases/download/v$(version)/julia-$(version)-x86_64-w64-mingw32.tar.gz",
                  "c7b2db68156150d0e882e98e39269301d7bf56660f4fc2e38ed2734a7a8d1551"; unpack_target="x86_64-w64-mingw32-libgfortran4-cxx11"),
    #ArchiveSource("https://julialang-s3.julialang.org/bin/winnt/x86/$(version.major).$(version.minor)/julia-$(version)-win32.tar.gz",
    #              "TODO"; unpack_target="i686-w64-mingw32-libgfortran4-cxx11"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/freebsd/x64/$(version.major).$(version.minor)/julia-$(version)-freebsd-x86_64.tar.gz",
                  "11b14de622f784a2b4842f8a26bc0876adda55f6204541638502acacc4a1d124"; unpack_target="x86_64-unknown-freebsd11.1-libgfortran4-cxx11"),
]
script = raw"""
cp -rva ${WORKSPACE}/srcdir/${bb_full_target}/julia*/* ${prefix}/
find . -name '._*' | xargs rm
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
