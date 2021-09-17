using BinaryBuilder, Pkg

name = "MKL"
version = v"2021.1.1"

# Bash recipes for building across all platforms
script = read(joinpath(@__DIR__, "script.sh"), String)
script_macos = read(joinpath(@__DIR__, "script_macos.sh"), String)

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

platform_sources = Dict(
    Platform("x86_64", "linux"; libc="glibc") => (
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2021.1.1/download/linux-64/mkl-2021.1.1-intel_52.tar.bz2",
            "bfb0fd056576cad99ae1d9c69ada2745420da9f9cf052551d5b91f797538bda2";
            unpack_target = "mkl-x86_64-linux-gnu"
        ),
        # We need to run autofix on Linux, because here libmkl_rt doesn't
        # have a soname, so we can't ccall it without specifying the path:
        # https://github.com/JuliaSparse/Pardiso.jl/issues/69
        autofix = true,
        script = script,
        args = ARGS,
    ),
    Platform("i686", "linux"; libc="glibc") => (
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2021.1.1/download/linux-32/mkl-2021.1.1-intel_52.tar.bz2",
            "7b6f55a30886154bd96d4b4c6b7428494a59397b87779b58e5b3de00250343f9";
            unpack_target = "mkl-i686-linux-gnu"
        ),
        autofix = true,
        script = script,
        args = ARGS,
    ),
    Platform("x86_64", "macos") => (
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2021.1.1/download/osx-64/mkl-2021.1.1-intel_50.tar.bz2",
            "819fb8875909d4d024e2a936c54b561aebd1e3aebe58fc605c70aa1ad9a66b70";
            unpack_target = "mkl-x86_64-apple-darwin14"
        ),
        # Need to disable autofix: updating linkage of libmkl_intel_thread.dylib on
        # macOS causes runtime issues:
        # https://github.com/JuliaPackaging/Yggdrasil/issues/915.
        autofix = false,
        script = script_macos,
        args = non_reg_ARGS,
    ),
    Platform("i686", "windows") => (
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2021.1.1/download/win-32/mkl-2021.1.1-intel_52.tar.bz2",
            "dba6a12a481407ec55fba9895b68afacb15f044905dcb5e185db341b688e6177";
            unpack_target = "mkl-i686-w64-mingw32"
        ),
        autofix = false,
        script = script,
        args = non_reg_ARGS,
    ),
    Platform("x86_64", "windows") => (
        source = ArchiveSource(
            "https://anaconda.org/intel/mkl/2021.1.1/download/win-64/mkl-2021.1.1-intel_52.tar.bz2",
            "4024391b8a45836d5a7ee92405b7767874b3c3bbf2f490349fda042db3b60dfd";
            unpack_target = "mkl-x86_64-w64-mingw32"
        ),
        autofix = false,
        script = script,
        args = non_reg_ARGS,
    ),
)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmkl_core", "mkl_core", "mkl_core.1"], :libmkl_core),
    LibraryProduct(["libmkl_rt", "mkl_rt", "mkl_rt.1"], :libmkl_rt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("IntelOpenMP_jll"),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
include("../../fancy_toys.jl")
filter!(p -> should_build_platform(triplet(first(p))), platform_sources)

for (platform, (source, autofix, script, args)) in pairs(platform_sources)
    build_tarballs(args, name, version, [source], script, [platform], products, dependencies; lazy_artifacts = true, autofix = autofix)
end
