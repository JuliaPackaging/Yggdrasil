using BinaryBuilder

name = "Julia"
version = v"1.0.0"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
#    FreeBSD(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
#    Linux(:armv7l; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
#    Linux(:aarch64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Linux(:i686; libc=:glibc, compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Windows(:x86_64; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
    Windows(:i686; compiler_abi=CompilerABI(libgfortran_version=v"4", cxxstring_abi=:cxx11)),
]

bin_prefix = "https://github.com/JuliaPackaging/JuliaBuilder/releases/download/v1.0.0-2/"
sources = [
    ArchiveSource("$bin_prefix/julia-1.0.0-x86_64-linux-gnu.tar.gz", "34b6e59acf8970a3327cf1603a8f90fa4da8e5ebf09e6624509ac39684a1835d"; unpack_target="x86_64-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("$bin_prefix/julia-1.0.0-i686-linux-gnu.tar.gz", "8d06061e714426ba4cd27bfafffd70bb29f8061b30e8476c6d24e05d0f85e215"; unpack_target="i686-linux-gnu-libgfortran4-cxx11"),
    ArchiveSource("$bin_prefix/julia-1.0.0-x86_64-apple-darwin14.tar.gz", "a9537f53306f9cf4f0f376f737c745c16b78e9cf635a0b22fbf0562713454b10"; unpack_target="x86_64-apple-darwin14-libgfortran4-cxx11"),
    ArchiveSource("$bin_prefix/julia-1.0.0-x86_64-w64-mingw32.tar.gz", "9c58bc0873e52cf6c41108a7a2b100f68419478f10c6fe635197b1bf47eec64d"; unpack_target="x86_64-w64-mingw32-libgfortran4-cxx11"),
    ArchiveSource("$bin_prefix/julia-1.0.0-i686-w64-mingw32.tar.gz", "32b1371b24eced2f9d9c505194b37474983a789f5d9c7169f6a277c014f96559"; unpack_target="i686-w64-mingw32-libgfortran4-cxx11"),
]
script = raw"""
cp -rva ${WORKSPACE}/srcdir/${bb_full_target}/* ${prefix}/
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
