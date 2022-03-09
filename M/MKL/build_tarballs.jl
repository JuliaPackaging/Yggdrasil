using BinaryBuilder, Pkg

name = "MKL"
version = v"2022.0.0"

# Bash recipes for building across all platforms
script = read(joinpath(@__DIR__, "script.sh"), String)
script_macos = read(joinpath(@__DIR__, "script_macos.sh"), String)

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

platform_sources = [
    (
        platform = Platform("x86_64", "linux"; libc="glibc"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2022.0.1/download/linux-64/mkl-2022.0.1-intel_117.tar.bz2",
            "62a3567efd4fa413181753dfc36c15bdfc8ec500eae4e5dcb104ed0d24136cfa";
            unpack_target = "mkl-x86_64-linux-gnu"
        ),
        # We need to run autofix on Linux, because here libmkl_rt doesn't
        # have a soname, so we can't ccall it without specifying the path:
        # https://github.com/JuliaSparse/Pardiso.jl/issues/69
        autofix = true,
        script = script,
    ),
    (
        platform = Platform("i686", "linux"; libc="glibc"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2022.0.1/download/linux-32/mkl-2022.0.1-intel_117.tar.bz2",
            "fd800f09432a214dfffe9b973f24fdfd374aa013d6b92fbd570c744aa7eef5b2";
            unpack_target = "mkl-i686-linux-gnu"
        ),
        autofix = true,
        script = script,
    ),
    (
        platform = Platform("x86_64", "macos"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2022.0.0/download/osx-64/mkl-2022.0.0-intel_105.tar.bz2",
            "fc026812458fd2053a6327bb5a42f47f97258147c39111bd6376dfabe51d05f5";
            unpack_target = "mkl-x86_64-apple-darwin14"
        ),
        # Need to disable autofix: updating linkage of libmkl_intel_thread.dylib on
        # macOS causes runtime issues:
        # https://github.com/JuliaPackaging/Yggdrasil/issues/915.
        autofix = false,
        script = script_macos,
    ),
    (
        platform = Platform("i686", "windows"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2022.0.0/download/win-32/mkl-2022.0.0-intel_115.tar.bz2",
            "045c6f3ca31eca1e07785980152ad6a74513bead1f20beab440eded9596452a9";
            unpack_target = "mkl-i686-w64-mingw32"
        ),
        autofix = false,
        script = script,
    ),
    (
        platform = Platform("x86_64", "windows"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2022.0.0/download/win-64/mkl-2022.0.0-intel_115.tar.bz2",
            "ba5a1f936b4e9fec0e3b5ae3ce44b56d06a6645a7c9456aa298c7d7373fd34c2";
            unpack_target = "mkl-x86_64-w64-mingw32"
        ),
        autofix = false,
        script = script,
    ),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmkl_core", "mkl_core", "mkl_core.2"], :libmkl_core),
    LibraryProduct(["libmkl_rt", "mkl_rt", "mkl_rt.2"], :libmkl_rt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("IntelOpenMP_jll"),
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
