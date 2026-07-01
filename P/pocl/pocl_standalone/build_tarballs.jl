# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

# This is the standalone (OpenCL-less) variant of the PoCL 7.2 track: instead of an ICD
# driver loaded by an OpenCL ICD loader, it builds a directly-linkable library
# (`libpocl_standalone`) whose OpenCL entrypoints are renamed to `PO<cl_function>`
# (RENAME_POCL). That lets it be used as a CPU back-end (e.g. by KernelAbstractions.jl's
# nanoOpenCL) without an OpenCL.jl/ICD dependency, while still coexisting in-process with a
# real OpenCL ICD targeting other GPUs. The actual build lives in ../common.jl, shared with
# the `pocl_next` (ICD) variant and selected via its `standalone` argument (true here).
# Like `pocl_next` this is a JIT build, so it needs no run-time clang/lld/llvm-spirv tooling.

name = "pocl_standalone"
version = v"7.2.0"
llvm_version = v"20.1.2"

# Build

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    GitSource("https://github.com/JuliaGPU/pocl",
              "33dde9515606b5965cc4aa1280d189497bfaa17a"),
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
    LibraryProduct(["libpocl_standalone", "pocl_standalone"], :libpocl),
    ExecutableProduct("poclcc", :poclcc),
]

# Dependencies that must be installed before this package can be built.
#
# Unlike the `pocl_next` (ICD) variant, the standalone build does not use an OpenCL ICD
# loader (ENABLE_ICD=OFF) and uses PoCL's vendored OpenCL headers, so OpenCL_jll and
# OpenCL_Headers_jll are not needed. As with `pocl_next`, the JIT build no longer shells
# out to an external linker or clang at run time (no LLD_unified_jll/Clang_unified_jll);
# with Level Zero disabled there is no spirv-link consumer (no SPIRV_Tools_jll); and the
# SPIR-V translator is vendored and statically linked (no SPIRV_LLVM_Translator_jll).
# LLVM_full_jll is only a build dependency because it is linked statically into libpocl.
dependencies = [
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    Dependency("Hwloc_jll"),
    Dependency("Zstd_jll"), # our LLVM 20 build has LLVM_ENABLE_ZSTD=ON
]

builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    platform_sources = deepcopy(sources)
    platform_dependencies = deepcopy(dependencies)

    # Vectorize OpenCL math builtins via SLEEF's libmvec-ABI / SLEEF compat library
    # (libsleefgnuabi), which the in-process JIT dlopens at run time (see common.jl for the
    # matching CMake flags). Gated to x86_64/aarch64 on the ELF OSes where LLVM maps a veclib
    # *and* SLEEF_jll ships libsleefgnuabi: Linux and FreeBSD (not macOS -- no GNUABI on
    # Mach-O -- and not Windows -- no SLEEF_jll). Even though this is the "standalone"
    # (JLL-dependency-free in spirit) build, a dynamic SLEEF_jll dep is the natural fit: the
    # JIT resolves _ZGV* symbols by dlopen, not by static linking.
    if (Sys.islinux(platform) || Sys.isfreebsd(platform)) && arch(platform) in ["x86_64", "aarch64"]
        push!(platform_dependencies, Dependency("SLEEF_jll"))
    end

    # On Windows we now link PoCL with the Clang/lld toolchain, but still build against this
    # GCC's MinGW sysroot and libstdc++, so its version must stay compatible with the
    # Clang-built LLVM_full_jll's libstdc++ ABI. (Previously pinned to 13 for GNU ld's
    # `.drectve -exclude-symbols`, used to dodge the PE export-ordinal limit; lld no longer
    # needs that -- it exports only the dllexport'd public API instead.)
    # _Float16 host support (cl_khr_fp16) requires the host C/C++ compiler to know the
    # `_Float16` type, which GCC only gained in v12 (HOST_COMPILER_SUPPORTS_FLOAT16 fails
    # on GCC 10/11 -> FP16 silently disabled). Keep >=12 so FP16 is enabled on the builds.
    preferred_gcc_version = if Sys.iswindows(platform)
        v"13"
    else
        v"12"
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
                   name, version, build.sources, build_script(true),
                   [build.platform], products, build.dependencies;
                   build.preferred_gcc_version,
                   preferred_llvm_version=Base.thismajor(llvm_version),
                   julia_compat="1.6", init_block=init_block(true))
end
