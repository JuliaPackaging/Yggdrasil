# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "pocl"
version = v"7.1.3"

# Build

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    GitSource("https://github.com/juliagpu/pocl",
              "21d408ea0adbfd59934d5720132c0e7f412af98e"),
    # vendored SPIR-V translator, built as a static library against our LLVM (see
    # common.jl); this commit is the LLVM-20.1-compatible revision (matches
    # LLVM_full_jll 20.1.2).
    GitSource("https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git",
              "dee371987a59ed8654083c09c5f1d5c54f5db318"),
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

include("../common.jl")

# LLVM 20 was built against the macOS 10.14 SDK, so ship it. We only use the
# helper for the (centralized) SDK source; the install itself is done
# non-destructively in common.jl, which extracts the SDK to a scratch dir and
# redirects the toolchain at it, rather than overwriting the read-only sys-root
# (whose `System` tree can no longer be `rm`'d on the current rootfs).
sources = vcat(sources, get_macos_sdk_sources("10.14"))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpocl", "pocl"], :libpocl),
    ExecutableProduct("poclcc", :poclcc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version="20.1.2")),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version="20.1.2")),
    Dependency("OpenCL_jll"),
    Dependency("OpenCL_Headers_jll"),
    Dependency("Hwloc_jll"),
    Dependency("Zstd_jll"), # our LLVM 20 build has LLVM_ENABLE_ZSTD=ON
    # the SPIR-V translator is vendored and statically linked (see common.jl), so
    # SPIRV_LLVM_Translator_jll is no longer needed at run time.
    # only used at run time, but also detected by the build
    Dependency("SPIRV_Tools_jll"),
    # only used at run time
    RuntimeDependency("Clang_unified_jll"),
    RuntimeDependency("LLD_unified_jll")
]

builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    platform_sources = deepcopy(sources)
    platform_dependencies = deepcopy(dependencies)

    # for fp16, we need a vectorization library
    if arch(platform) in ["armv6l", "aarch64"]
        #push!(platform_dependencies, Dependency("SLEEF_jll"))
        # XXX: PoCL hard-codes the path to libsleef
        # `no such file or directory: '/opt/aarch64-linux-gnu/aarch64-linux-gnu/sys-root/usr/local/lib/libsleef.so'`
    end
    # TODO: libsvml for x86 (part of mkl)
    # TODO: libmvec as fallback (part of glibc 2.22+)

    # On Windows we now link PoCL with the Clang/lld toolchain, but still build against this
    # GCC's MinGW sysroot and libstdc++, so its version must stay compatible with the
    # Clang-built LLVM_full_jll's libstdc++ ABI. (Previously pinned to 13 for GNU ld's
    # `.drectve -exclude-symbols`, used to dodge the PE export-ordinal limit; lld no longer
    # needs that -- it exports only the dllexport'd public API instead.)
    preferred_gcc_version = if Sys.iswindows(platform)
        v"13"
    else
        v"10"
    end

    push!(builds, (; platform,
                     preferred_gcc_version,
                     sources=platform_sources,
                     dependencies=platform_dependencies))
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
                   [build.platform], products, build.dependencies;
                   build.preferred_gcc_version, preferred_llvm_version=v"20",
                   julia_compat="1.6", init_block=init_block())
end
