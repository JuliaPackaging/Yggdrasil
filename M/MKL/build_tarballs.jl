using BinaryBuilder, Pkg

name = "MKL"
version = v"2022.2.0"

# Bash recipes for building across all platforms
script = read(joinpath(@__DIR__, "script.sh"), String)
script_macos = read(joinpath(@__DIR__, "script_macos.sh"), String)

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

platform_sources = [
    (
        platform = Platform("x86_64", "linux"; libc="glibc"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2022.2.0/download/linux-64/mkl-2022.2.0-intel_8748.tar.bz2",
            "1f3f5e6f4c2d8ea3b4792d2d9a116492e4dac4914373c415ea1272d0f55491ff";
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
            "https://anaconda.org/intel/mkl/2022.2.0/download/linux-32/mkl-2022.2.0-intel_8748.tar.bz2",
            "f14784822632cff8a926998c1779833f8dd6b86219b7e8744ccb535cad15023d";
            unpack_target = "mkl-i686-linux-gnu"
        ),
        autofix = true,
        script = script,
    ),
    (
        platform = Platform("x86_64", "macos"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2022.2.0/download/osx-64/mkl-2022.2.0-intel_8687.tar.bz2",
            "d47572cf4fb018ce8e5db8a4732055b46bcc50cc4d2f8dc2d7d5ae83ca227c69";
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
            "https://anaconda.org/intel/mkl/2022.2.0/download/win-32/mkl-2022.2.0-intel_9563.tar.bz2",
            "60435411e0ca283b2b45f979f16520f390ca28588d1d6d2c0682cbda55e6b61f";
            unpack_target = "mkl-i686-w64-mingw32"
        ),
        autofix = false,
        script = script,
    ),
    (
        platform = Platform("x86_64", "windows"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2022.2.0/download/win-64/mkl-2022.2.0-intel_9563.tar.bz2",
            "59e89f45c6d604d18dfef972a973e3ec4a5d69d02d0fc173d20637fa6e8b59e9";
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
