# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "pocl_standalone"
version = v"7.0"

# Collection of sources required to complete build
sources = [
    DirectorySource("../pocl/bundled"),
    GitSource("https://github.com/pocl/pocl",
              "33518641e79bf9e693db8638176d1b194b6ea0da")
]

include("../pocl/common.jl")
script = """
STANDALONE=1
""" * script_common

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
## i686-musl doesn't have LLVM
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
## Windows support is unmaintained
filter!(!Sys.iswindows, platforms)
## freebsd-aarch64 doesn't have an LLVM_full_jll build yet
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpocl", :libpocl),
    ExecutableProduct("poclcc", :poclcc),
]


init_block = raw"""
    # expose JLL binaries to the library
    # XXX: Scratch.jl is unusably slow with JLLWrapper-emitted @compiler_options
    #bindir = @get_scratch!("bin")
    bindir = abspath(first(Base.DEPOT_PATH), "scratchspaces", string(Base.PkgId(@__MODULE__).uuid), "bin")
    mkpath(bindir)
    function generate_wrapper_script(name, path, LIBPATH, PATH)
        if Sys.iswindows()
            LIBPATH_env = "PATH"
            LIBPATH_default = ""
            pathsep = ';'
        elseif Sys.isapple()
            LIBPATH_env = "DYLD_FALLBACK_LIBRARY_PATH"
            LIBPATH_default = "~/lib:/usr/local/lib:/lib:/usr/lib"
            pathsep = ':'
        else
            LIBPATH_env = "LD_LIBRARY_PATH"
            LIBPATH_default = ""
            pathsep = ':'
        end

        # XXX: cache, but invalidate when deps change
        script = joinpath(bindir, name)
        if Sys.isunix()
            open(script, "w") do io
                println(io, "#!/bin/bash")

                LIBPATH_base = get(ENV, LIBPATH_env, expanduser(LIBPATH_default))
                LIBPATH_value = if !isempty(LIBPATH_base)
                    string(LIBPATH, pathsep, LIBPATH_base)
                else
                    LIBPATH
                end
                println(io, "export $LIBPATH_env=\\"$LIBPATH_value\\"")

                if LIBPATH_env != "PATH"
                    PATH_base = get(ENV, "PATH", "")
                    PATH_value = if !isempty(PATH_base)
                        string(PATH, pathsep, ENV["PATH"])
                    else
                        PATH
                    end
                    println(io, "export PATH=\\"$PATH_value\\"")
                end

                println(io, "exec \\"$path\\" \\"\$@\\"")
            end
            chmod(script, 0o755)
        else
            error("Unsupported platform")
        end
        return script
    end
    ENV["POCL_PATH_SPIRV_LINK"] =
        generate_wrapper_script("spirv_link", SPIRV_Tools_jll.spirv_link_path,
                                SPIRV_Tools_jll.LIBPATH[], SPIRV_Tools_jll.PATH[])
    ENV["POCL_PATH_CLANG"] =
        generate_wrapper_script("clang", Clang_unified_jll.clang_path,
                                Clang_unified_jll.LIBPATH[], Clang_unified_jll.PATH[])
    ENV["POCL_PATH_LLVM_SPIRV"] =
        generate_wrapper_script("llvm-spirv",
                                SPIRV_LLVM_Translator_unified_jll.llvm_spirv_path,
                                SPIRV_LLVM_Translator_unified_jll.LIBPATH[],
                                SPIRV_LLVM_Translator_unified_jll.PATH[])
    ld_path = if Sys.islinux()
            LLD_unified_jll.ld_lld_path
        elseif Sys.isapple()
            LLD_unified_jll.ld64_lld_path
        elseif Sys.iswindows()
            LLD_unified_jll.lld_link_path
        else
            error("Unsupported platform")
        end
    ld_wrapper = generate_wrapper_script("lld", ld_path,
                                         LLD_unified_jll.LIBPATH[],
                                         LLD_unified_jll.PATH[])
    ENV["POCL_ARGS_CLANG"] = join([
            "-fuse-ld=lld", "--ld-path=$ld_wrapper",
            "-L" * joinpath(artifact_dir, "share", "lib")
        ], ";")
"""

# determine exactly which tarballs we should build
builds = []

dependencies = [
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version=v"19")),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"19")),
    # BuildDependency("OpenCL_jll"),
    Dependency("SPIRV_LLVM_Translator_jll"),
    Dependency("SPIRV_Tools_jll"),
    Dependency("Clang_unified_jll"),
    Dependency("LLD_unified_jll"),
]

for platform in platforms
    augmented_platform = deepcopy(platform)

    should_build_platform(triplet(augmented_platform)) || continue
    push!(builds, (;
        dependencies,
        platforms=[augmented_platform],
        preferred_llvm_version=v"19",
    ))
end


# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, script,
                   build.platforms, products, build.dependencies;
                   preferred_gcc_version=v"10", build.preferred_llvm_version,
                   julia_compat="1.6", init_block)
end
