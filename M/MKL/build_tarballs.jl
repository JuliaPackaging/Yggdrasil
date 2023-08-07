using BinaryBuilder, Pkg

name = "MKL"
version = v"2023.2.0"

# Bash recipes for building across all platforms
script = read(joinpath(@__DIR__, "script.sh"), String)
script_macos = read(joinpath(@__DIR__, "script_macos.sh"), String)

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

platform_sources = [
    (
        platform = Platform("i686", "windows"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.2.0/download/win-32/mkl-2023.2.0-intel_49496.tar.bz2",
            "c30057ce3372302e23953309a0baa734b45af253c88d94e1842d33037d0157f9";
            unpack_target = "mkl-i686-w64-mingw32"
        ),
        autofix = false,
        script = script,
    ),
    (
        platform = Platform("x86_64", "windows"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.2.0/download/win-64/mkl-2023.2.0-intel_49496.tar.bz2",
            "fb484eea6a60baedb5368a40a42fa7be5f3da5131b8fe1edd7a732b9ddeb41a6";
            unpack_target = "mkl-x86_64-w64-mingw32"
        ),
        autofix = false,
        script = script,
    ),
    (
        platform = Platform("i686", "linux"; libc="glibc"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.2.0/download/linux-32/mkl-2023.2.0-intel_49495.tar.bz2",
            "751222f86ed5a09888d4b18eb777abc30ac6159123700b264850c0c3a694c927";
            unpack_target = "mkl-i686-linux-gnu"
        ),
        autofix = true,
        script = script,
    ),
    (
        platform = Platform("x86_64", "linux"; libc="glibc"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.2.0/download/linux-64/mkl-2023.2.0-intel_49495.tar.bz2",
            "209c121b304fa22948b13930607f351fd5f64cb520eeeb6374c784b6187312e2";
            unpack_target = "mkl-x86_64-linux-gnu"
        ),
        # We need to run autofix on Linux, because here libmkl_rt doesn't
        # have a soname, so we can't ccall it without specifying the path:
        # https://github.com/JuliaSparse/Pardiso.jl/issues/69
        autofix = true,
        script = script,
    ),
    (
        platform = Platform("x86_64", "macos"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.2.0/download/osx-64/mkl-2023.2.0-intel_49499.tar.bz2",
            "aef64fe708b9f6ae7edfaa5e861e954d9bb78e48ff810f9c93237ad716fbe6db";
            unpack_target = "mkl-x86_64-apple-darwin14"
        ),
        # Need to disable autofix: updating linkage of libmkl_intel_thread.dylib on
        # macOS causes runtime issues:
        # https://github.com/JuliaPackaging/Yggdrasil/issues/915.
        autofix = false,
        script = script_macos,
    )
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmkl_core", "mkl_core", "mkl_core.2"], :libmkl_core),
    LibraryProduct(["libmkl_rt", "mkl_rt", "mkl_rt.2"], :libmkl_rt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="IntelOpenMP_jll", uuid="1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0")),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
include("../../fancy_toys.jl")
filter!(p -> should_build_platform(triplet(first(p))), platform_sources)

for (idx, (platform, source, autofix, script)) in enumerate(platform_sources)
    # Use "--register" only on the last invocation of build_tarballs
    if idx < length(platform_sources)
        args = non_reg_ARGS
    else
        args = ARGS
    end
    build_tarballs(args, name, version, [source], script, [platform], products, dependencies; lazy_artifacts = true, autofix = autofix)
end
