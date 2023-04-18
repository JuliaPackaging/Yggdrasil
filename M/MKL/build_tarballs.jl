using BinaryBuilder, Pkg

name = "MKL"
version = v"2023.1.0"

# Bash recipes for building across all platforms
script = read(joinpath(@__DIR__, "script.sh"), String)
script_macos = read(joinpath(@__DIR__, "script_macos.sh"), String)

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

platform_sources = [
    (
        platform = Platform("i686", "windows"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.1.0/download/win-32/mkl-2023.1.0-intel_46356.tar.bz2",
            "b84848ab6a9b785171a58f8bf96e4843fb695e66af804d31f75e86877d53c7da";
            unpack_target = "mkl-i686-w64-mingw32"
        ),
        autofix = false,
        script = script,
    ),
    (
        platform = Platform("x86_64", "windows"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.1.0/download/win-64/mkl-2023.1.0-intel_46356.tar.bz2",
            "767fbbe50157e9f365eca77d42a1495b66661b5845a1c13b8e33fe79d3b4a9f4";
            unpack_target = "mkl-x86_64-w64-mingw32"
        ),
        autofix = false,
        script = script,
    ),
    (
        platform = Platform("i686", "linux"; libc="glibc"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.1.0/download/linux-32/mkl-2023.1.0-intel_46342.tar.bz2",
            "ed00993f38f05e39252c718b6041d422f1217c015d3a62faa1f294cc7f089430";
            unpack_target = "mkl-i686-linux-gnu"
        ),
        autofix = true,
        script = script,
    ),
    (
        platform = Platform("x86_64", "linux"; libc="glibc"),
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2023.1.0/download/linux-64/mkl-2023.1.0-intel_46342.tar.bz2",
            "3820a9053b1c028b3d9f62448f7d0d53a57ca6d6d38c2279faec8663f27d0a5c";
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
            "https://anaconda.org/intel/mkl/2023.1.0/download/osx-64/mkl-2023.1.0-intel_43558.tar.bz2",
            "a4c7a5e322ebb988aa914c3dbdc88afd241c1f50d2fac3f919d3ebca4df4727d";
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
