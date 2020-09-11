# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.Types

# Collection of sources required to build GMP
function configure(version)
    name = "libjulia"

    checksums = Dict(
        v"1.4.2" => "76a94e06e68fb99822e0876a37c2ed3873e9061e895ab826fd8c9fc7e2f52795",
        v"1.5.1" => "1f138205772eb1e565f1d7ccd6f237be8a4d18713a3466e3b8d3a6aad6483fd9",
    )
    sources = [
        ArchiveSource("https://github.com/JuliaLang/julia/releases/download/v$(version)/julia-$(version).tar.gz", checksums[version]),
    ]

    # Bash recipe for building across all platforms
    script = raw"""
    cd $WORKSPACE/srcdir/julia*

    FLAGS=(
        USE_SYSTEM_LLVM=1
        USE_SYSTEM_LIBUNWIND=1
        USE_SYSTEM_PCRE=1
        USE_SYSTEM_OPENLIBM=1
        USE_SYSTEM_DSFMT=1
        USE_SYSTEM_BLAS=1
        LIBBLASNAME=libopenblas
        USE_SYSTEM_LAPACK=1
        LIBLAPACKNAME=libopenblas
        USE_SYSTEM_GMP=1
        USE_SYSTEM_MPFR=1
        USE_SYSTEM_SUITESPARSE=1
        USE_SYSTEM_LIBUV=1
        USE_SYSTEM_UTF8PROC=1
        USE_SYSTEM_MBEDTLS=1
        USE_SYSTEM_LIBSSH2=1
        USE_SYSTEM_CURL=1
        USE_SYSTEM_LIBGIT2=1
        USE_SYSTEM_PATCHELF=1
        USE_SYSTEM_ZLIB=1
        USE_SYSTEM_P7ZIP=1

        NO_GIT=1
        prefix="${prefix}"
        -j${nproc}
    )

    # compile libjulia but don't try to build a sysimage
    make "${FLAGS[@]}" julia-ui-release
    cp usr/lib/libjulia* ${libdir}/
    install_license /usr/share/licenses/MIT
    """

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = expand_cxxstring_abis(supported_platforms())

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libjulia", :libjulia; dont_dlopen=true),
    ]

    # Dependencies that must be installed before this package can be built/used
    dependencies = [
        Dependency("LibUnwind_jll"),
        Dependency("LibOSXUnwind_jll"),
        Dependency(PackageSpec(name="PCRE2_jll", version=v"10.31")),
        Dependency("OpenLibm_jll"),
        Dependency("dSFMT_jll"),
        Dependency(PackageSpec(name="SuiteSparse_jll", version=v"5.4.0")),
        Dependency("LibUV_jll"),
        Dependency("utf8proc_jll"),
        Dependency("MbedTLS_jll"),
        Dependency("LibSSH2_jll"),
        Dependency("LibCURL_jll"),
        Dependency("Patchelf_jll"),
        Dependency("Zlib_jll"),
        Dependency("p7zip_jll"),
    ]
    if version.major == 1 && version.minor == 4
        push!(dependencies, Dependency(PackageSpec(name="OpenBLAS_jll", version=v"0.3.5")))
        push!(dependencies, Dependency(PackageSpec(name="libLLVM_jll", version=v"8.0.1")))
        push!(dependencies, Dependency(PackageSpec(name="MPFR_jll", version=v"4.0.2")))
        push!(dependencies, Dependency(PackageSpec(name="GMP_jll", version=v"6.1.2")))
        push!(dependencies, Dependency(PackageSpec(name="LibGit2_jll", version=v"0.28.2")))
    elseif version.major == 1 && version.minor == 5
        push!(dependencies, Dependency(PackageSpec(name="OpenBLAS_jll", version=v"0.3.9")))
        push!(dependencies, Dependency(PackageSpec(name="libLLVM_jll", version=v"9.0.1")))
        push!(dependencies, Dependency(PackageSpec(name="MPFR_jll", version=v"4.1.0")))
        push!(dependencies, Dependency(PackageSpec(name="GMP_jll", version=v"6.1.2")))
        push!(dependencies, Dependency(PackageSpec(name="LibGit2_jll", version=v"0.28.2")))
    elseif version.major == 1 && version.minor == 6
        push!(dependencies, Dependency(PackageSpec(name="OpenBLAS_jll", version=v"0.3.10")))
        push!(dependencies, Dependency(PackageSpec(name="libLLVM_jll", version=v"9.0.1")))
        push!(dependencies, Dependency(PackageSpec(name="MPFR_jll", version=v"4.1.0")))
        push!(dependencies, Dependency(PackageSpec(name="GMP_jll", version=v"6.2.0")))
        push!(dependencies, Dependency(PackageSpec(name="LibGit2_jll", version=v"1.0.1")))
    end

    return name, version, sources, script, platforms, products, dependencies
end

