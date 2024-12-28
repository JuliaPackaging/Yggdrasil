# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

name = "libblastrampoline"

# Collection of sources required to build libblastrampoline
function lbt_sources(version::VersionNumber; kwargs...)
    lbt_version_commit = Dict(
        v"5.4.0"  => "d00e6ca235bb747faae4c9f3a297016cae6959ed",
        v"5.11.2" => "c48da8a1225c2537ff311c28ef395152fb879eae",
        v"5.12.0" => "b127bc8dd4758ffc064340fff2aef4ead552f386",
    )

    return [
        GitSource("https://github.com/JuliaLinearAlgebra/libblastrampoline.git",
                  lbt_version_commit[version]),
        DirectorySource("./bundled/")
    ]
end

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libblastrampoline/src

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

make -j${nproc} prefix=${prefix} install

install -Dvm644 ../../cmake/yggdrasilenv.cmake ${libdir}/cmake/blastrampoline/yggdrasilenv.cmake
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libblastrampoline", :libblastrampoline)
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll",
                                uuid="4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version=llvm_version);
    platforms=filter(p -> sanitize(p)=="memory", platforms)),
]
