# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "SSW"
version = v"1.2.5"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/mengyao/Complete-Striped-Smith-Waterman-Library.git",
        "c32f4c2b07df137a0fce72ec7c7e60474937a52e",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Complete-Striped-Smith-Waterman-Library
install_license README.md
cd src/
make -j${nproc} default
install -Dvm 755 "libssw.${dlext}" "${libdir}/libssw.${dlext}"
install -Dvm 755 "ssw_test${exeext}" "${bindir}/ssw_test${exeext}"
install -Dvm 755 "example_c${exeext}" "${bindir}/example_c${exeext}"
install -Dvm 755 "example_cpp${exeext}" "${bindir}/example_cpp${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# NOTE: Windows builds require Cygwin (sys/mman dependency)
platforms = filter(
    p ->
        (Sys.islinux(p) || Sys.isfreebsd(p)) &&
            (arch(p) == "x86_64" || arch(p) == "aarch64"),
    supported_platforms(),
)
platforms = expand_cxxstring_abis(platforms) 

# The products that we will ensure are always built
# NOTE: last-dotplot not supported due to Python Dependency
products = Product[
    LibraryProduct("libssw", :libssw),
    ExecutableProduct("ssw_test", :ssw_test),
    ExecutableProduct("example_c", :example_c),
    ExecutableProduct("example_cpp", :example_cpp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(; name = "Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a"),
    ),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"6",
)

