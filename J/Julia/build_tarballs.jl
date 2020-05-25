using BinaryBuilder

name = "Julia"
version = v"1.4.2"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    FreeBSD(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
#    Linux(:armv7l; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:aarch64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:i686; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
#    Windows(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
#    Windows(:i686; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
]

sources = [
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/linux/aarch64/1.4/julia-$(version)-linux-aarch64.tar.gz",
                  "f124d1b9fa68c3049d4ffe2349454f8ba1753d17d6578bc6e7cb916aed7cff4a"; unpack_target="aarch64-linux-gnu-libgfortran4-cxx11"),
#    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/linux/armv7l/1.4/julia-$(version)-linux-armv7l.tar.gz",
#                  ""; unpack_target="armv7l-linux-gnueabihf-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/linux/x64/1.4/julia-$(version)-linux-x86_64.tar.gz",
                  "d77311be23260710e89700d0b1113eecf421d6cf31a9cebad3f6bdd606165c28"; unpack_target="x86_64-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/linux/x86/1.4/julia-$(version)-linux-i686.tar.gz",
                  "ce821b6671a137dc7c2ccbf40ff08471a6791ea8af80a30d6716806608e72dab"; unpack_target="i686-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/mac/x64/1.4/julia-$(version)-mac64.tar.gz",
                  "660ecd64db812e642e2b9483966c61f7fec3ee88c84a1eb26831bfce2aa51ac9"; unpack_target="x86_64-apple-darwin14-libgfortran4-cxx11"),
#    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/winnt/x64/1.4/julia-$(version)-win64.tar.gz",
#                  ""; unpack_target="x86_64-w64-mingw32-libgfortran4-cxx11"),
#    ArchiveSource("https://julialang2.s3.amazonaws.com/bin/winnt/x86/1.4/julia-$(version)-win32.tar.gz",
#                  ""; unpack_target="i686-w64-mingw32-libgfortran4-cxx11"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/freebsd/x64/1.4/julia-$(version)-freebsd-x86_64.tar.gz",
                  "29892e81d663dc081281b8530fa2e949306da933dcf2d6d28a5dec165a92aa24"; unpack_target="x86_64-unknown-freebsd11.1-libgfortran4-cxx11"),
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
