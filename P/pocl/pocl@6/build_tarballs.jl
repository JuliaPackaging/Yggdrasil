# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "pocl"
version = v"6.0.1"

# POCL supports LLVM 14 to 18
# XXX: link statically to a single version of LLVM instead, and don't use augmentations?
#      this causes issue with the compile-time link, so I haven't explored this yet
llvm_versions = [v"15.0.7", v"16.0.6", v"18.1.7"]

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    GitSource("https://github.com/pocl/pocl",
              "952bc559f790e5deb5ae48692c4a19619b53fcdc")
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

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pocl/
install_license LICENSE

atomic_patch -p1 $WORKSPACE/srcdir/patches/freebsd.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/distro-generic.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/env-override.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/env-override-ld.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/env-override-args.patch

# POCL wants a target sysroot for compiling the host kernellib (for `math.h` etc)
sysroot=/opt/${target}/${target}/sys-root
if [[ "${target}" == *apple* ]]; then
    # XXX: including the sysroot like this doesn't work on Apple, missing definitions like
    #      TARGET_OS_IPHONE. it seems like these headers should be included using -isysroot,
    #      but (a) that doesn't seem to work, and (b) isn't that already done by the cmake
    #      toolchain file? work around the issue by inserting an include for the missing
    #      definitions at the top of the headers included from POCL's kernel library.
    sed -i '1s/^/#include <TargetConditionals.h>\n/' $sysroot/usr/include/stdio.h
fi
sed -i "s|COMMENT \\"Building C to LLVM bitcode \${BC_FILE}\\"|\\"-I$sysroot/usr/include\\"|" \
       cmake/bitcode_rules.cmake

CMAKE_FLAGS=()
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
# Enable optional debug messages for debuggability
CMAKE_FLAGS+=(-DPOCL_DEBUG_MESSAGES:Bool=ON)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
# Point to relevant LLVM tools (see above)
## HostDependency: llvm-config, but spoofed to return Dependency's paths
CMAKE_FLAGS+=(-DWITH_LLVM_CONFIG=$WORKSPACE/srcdir/llvm-config)
## Native toolchain: for LLVM tools to ensure they can target the right architecture
CMAKE_FLAGS+=(-DLLVM_BINDIR=/opt/$MACHTYPE/bin)
# Override the target and triple, which POCL takes from `llvm-config --host-target`
triple=$(clang -print-target-triple)
CMAKE_FLAGS+=(-DLLVM_HOST_TARGET=$triple)
CMAKE_FLAGS+=(-DLLC_TRIPLE=$triple)
# Override the auto-detected target CPU (which POCL takes from `llc --version`)
CPU=$(clang --print-supported-cpus 2>&1 | grep -P '\t' | head -n 1 | sed 's/\s//g')
CMAKE_FLAGS+=(-DLLC_HOST_CPU_AUTO=$CPU)
# Generate a portable build
CMAKE_FLAGS+=(-DKERNELLIB_HOST_CPU_VARIANTS=distro)
# Build POCL as an dynamic library loaded by the OpenCL runtime
CMAKE_FLAGS+=(-DENABLE_ICD:BOOL=ON)
# XXX: work around pocl#1528, disabling FP16 support in i686
if [[ ${target} == i686-* ]]; then
    CMAKE_FLAGS+=(-DHOST_CPU_SUPPORTS_FLOAT16:BOOL=OFF)
fi

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install

# PoCL uses Clang, which relies on certain system libraries Clang_jll.jl doesn't provide
mkdir -p $prefix/share/lib
if [[ ${target} == *-linux-gnu ]]; then
    if [[ "${nbits}" == 64 ]]; then
        cp -a $sysroot/lib64/libc{.,-}* $prefix/share/lib
        cp -a $sysroot/usr/lib64/libm.* $prefix/share/lib
        ln -sf libm.so.6 $prefix/share/lib/libm.so
        cp -a $sysroot/lib64/libm{.,-}* $prefix/share/lib
        cp -a /opt/${target}/${target}/lib64/libgcc_s.* $prefix/share/lib
        cp -a /opt/$target/lib/gcc/$target/*/*.{o,a} $prefix/share/lib
    else
        cp -a $sysroot/lib/libc{.,-}* $prefix/share/lib
        cp -a $sysroot/usr/lib/libm.* $prefix/share/lib
        ln -sf libm.so.6 $prefix/share/lib/libm.so
        cp -a $sysroot/lib/libm{.,-}* $prefix/share/lib
        cp -a /opt/${target}/${target}/lib/libgcc_s.* $prefix/share/lib
        cp -a /opt/$target/lib/gcc/$target/*/*.{o,a} $prefix/share/lib
    fi
elif [[ ${target} == *-linux-musl ]]; then
    cp -a $sysroot/usr/lib/*.{o,a} $prefix/share/lib
    cp -a /opt/$target/lib/gcc/$target/*/*.{o,a} $prefix/share/lib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
## i686-musl doesn't have LLVM
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
## Windows support is unmaintained
filter!(!Sys.iswindows, platforms)
## freebsd-aarch64 doesn't have an LLVM_full_jll build yet
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
## riscv64 doesn't have an LLVM_full_jll build yet
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpocl", :libpocl),
    ExecutableProduct("poclcc", :poclcc),
]

augment_platform_block = """
    using Base.BinaryPlatforms

    $(LLVM.augment)

    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

init_block = raw"""
    # Register this driver with OpenCL_jll
    if OpenCL_jll.is_available()
        push!(OpenCL_jll.drivers, libpocl)

        # XXX: Clang_jll does not have a functional clang binary on macOS,
        #      as it's configured without a default sdkroot (see #9221)
        if Sys.isapple()
            ENV["SDKROOT"] = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
        end
    end

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

        # write to temporary script
        temp_script, io = mktemp(bindir; cleanup=false)
        if Sys.isunix()
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
            close(io)
            chmod(temp_script, 0o755)
        else
            error("Unsupported platform")
        end

        # atomically move to the final location
        script = joinpath(bindir, name)
        @static if VERSION >= v"1.12.0-DEV.1023"
            mv(temp_script, script; force=true)
        else
            Base.rename(temp_script, script, force=true)
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

    # expose libc to Clang, even if the system doesn't have development symlinks
    libdir = abspath(first(Base.DEPOT_PATH), "scratchspaces", string(Base.PkgId(@__MODULE__).uuid), "lib")
    mkpath(libdir)
    for lib in Libdl.dllist()
        startswith(basename(lib), "libc.so.6") || continue
        link = joinpath(libdir, "libc.so")
        try
            symlink(lib, link)
        catch
            # can't safely check first, because multiple processes may be running
            islink(link) || rethrow()
        end
    end
    ENV["POCL_ARGS_CLANG"] = join([
            "-fuse-ld=lld", "--ld-path=$ld_wrapper",
            "-L", joinpath(artifact_dir, "share", "lib"),
            "-L", libdir
        ], ";")
"""

# determine exactly which tarballs we should build
builds = []
for llvm_version in llvm_versions, llvm_assertions in (false, true)
    # Dependencies that must be installed before this package can be built
    llvm_name = llvm_assertions ? "LLVM_full_assert_jll" : "LLVM_full_jll"
    dependencies = [
        HostBuildDependency(PackageSpec(name=llvm_name, version=llvm_version)),
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version)),
        Dependency("OpenCL_jll"),
        Dependency("Hwloc_jll"),
        Dependency("SPIRV_LLVM_Translator_unified_jll"),
        Dependency("SPIRV_Tools_jll"),
        Dependency("Clang_unified_jll"),
        Dependency("LLD_unified_jll"),
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies,
            platforms=[augmented_platform],
            preferred_llvm_version=Base.thismajor(llvm_version),
        ))
    end
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
                   julia_compat="1.6", augment_platform_block, init_block)
end
