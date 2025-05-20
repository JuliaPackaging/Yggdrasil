# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "pocl"
version = v"7.0.0"

# Build

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    GitSource("https://github.com/maleadt/pocl",
              "0d4baa74067db1f986fb7d70f40561c453be7b73")   # v7.0-RC2 + #1918
]

#=

PoCL wants to be linked against LLVM for run-time code generation, but also generates code
at compile time using LLVM tools, so we need to carefully select which of the different
builds of LLVM we need:

- the Dependency one, in $prefix: everything we want, but can't use it during the build as
  its binaries aren't executable here (hopefully they will be with BinaryBuilder2.jl).
- the HostDependency one, in $host_prefix: can't emit code for the target, but provides an
  llvm-config returning the right flags. so we use it as the llvm-config during the build,
  spoofing the returned paths to the Dependency ones.
- the native toolchain: supports the target, but can't be linked against, and provides the
  wrong LLVM flags. so we only use its tools during the build, requiring that the chosen
  LLVM version is compatible with the one used at run time, to avoid IR incompatibilities.

=#

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
## we don't build LLVM 15+ for i686-linux-musl.
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
## PoCL doesn't support 32-bit Windows
filter!(p -> !(arch(p) == "i686" && os(p) == "windows"), platforms)

include("common.jl")

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpocl", "pocl"], :libpocl),
    ExecutableProduct("poclcc", :poclcc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version=v"20.1.2")),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"20.1.2")),
    Dependency("OpenCL_jll"),
    Dependency("OpenCL_Headers_jll"),
    Dependency("Hwloc_jll"),
    Dependency("Zstd_jll"), # our LLVM 20 build has LLVM_ENABLE_ZSTD=ON
    # only used at run time, but also detected by the build
    Dependency("SPIRV_LLVM_Translator_jll", compat="20.1"),
    Dependency("SPIRV_Tools_jll"),
    # only used at run time
    RuntimeDependency("Clang_unified_jll"),
    RuntimeDependency("LLD_unified_jll")
]

builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # On macOS, we need to use a newer SDK to match the one LLVM was built with
    platform_sources = if Sys.isapple(platform)
        [sources;
         ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                       "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f")]
    else
        sources
    end

    # on Windows, we need to use a version of GCC that supports `.drectve -exclude-symbols`
    # or we run into export ordinal limits
    preferred_gcc_version = if Sys.iswindows(platform)
        v"13"
    else
        v"10"
    end

    push!(builds, (; platform, sources=platform_sources, preferred_gcc_version))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` and `--deploy` should only be passed to the final `build_tarballs` invocation
non_reg_ARGS = filter(non_platform_ARGS) do arg
    arg != "--register" && !startswith(arg, "--deploy")
end

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, build_script(),
                   [build.platform], products, dependencies;
                   build.preferred_gcc_version, preferred_llvm_version=v"20",
                   julia_compat="1.6", init_block=init_block())
end

# bump
