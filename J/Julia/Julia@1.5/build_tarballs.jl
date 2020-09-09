using BinaryBuilder

name = "Julia"
version = v"1.5.0"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    FreeBSD(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
#    Linux(:armv7l; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:aarch64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:i686; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Windows(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Windows(:i686; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
]

sources = [
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/aarch64/$(version.major).$(version.minor)/julia-$(version)-linux-aarch64.tar.gz",
                  "6c6f1d3b6d16829e1ecc0528bb8bb15f9fe90b03fcee99509a3fe625cac32c51"),
#    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/armv7l/$(version.major).$(version.minor)/julia-$(version)-linux-armv7l.tar.gz",
#                  ""),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/x64/$(version.major).$(version.minor)/julia-$(version)-linux-x86_64.tar.gz",
                  "be7af676f8474afce098861275d28a0eb8a4ece3f83a11027e3554dcdecddb91"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/x86/$(version.major).$(version.minor)/julia-$(version)-linux-i686.tar.gz",
                  "dafefde1fb1387730d804c7b4bb29c904311f0a52b12bf44c0c4ed4af6ae58e6"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/mac/x64/$(version.major).$(version.minor)/julia-$(version)-mac64.tar.gz",
                  "9c36a4366eafa15b4a3d4533dcd0ab8ed799eab13305f6662eca905e0480fc65"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/winnt/x64/$(version.major).$(version.minor)/julia-$(version)-win64.tar.gz",
                  "48a0203b7144e04679bec9500c927ef36dd450cfa8d2a9f4517192794eb7c9ba"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/winnt/x86/$(version.major).$(version.minor)/julia-$(version)-win32.tar.gz",
                  "d0d3bbcb8fa73c1d5e4eacb9e1d4fb3992979fed4056e4051d4a4b04e211268d"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/freebsd/x64/$(version.major).$(version.minor)/julia-$(version)-freebsd-x86_64.tar.gz",
                  "b07dc5b649828495350ed0729e003aa87da6f91e8a0f06ead9825d533b3d379f"),
]
script = raw"""
cp -rva ${WORKSPACE}/srcdir/julia-*/* ${prefix}/
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
