# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "pocl"
version = v"7.0"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    # DirectorySource("/home/tim/Julia/src/pocl"; target="pocl"),
    GitSource("https://github.com/pocl/pocl",
              "6accdd750d8ff66dbcc60c499b5aca5004e61c0e")
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

if [[ ("${target}" == x86_64-apple-darwin*) ]]; then
    # LLVM 15+ requires macOS SDK 10.14
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

# POCL wants a target sysroot for compiling the host kernellib (for `math.h` etc)
sysroot=/opt/${target}/${target}/sys-root
if [[ "${target}" == *-mingw* ]]; then
    sysroot_include=$sysroot/include
else
    sysroot_include=$sysroot/usr/include
fi
if [[ "${target}" == *apple* ]]; then
    # XXX: including the sysroot like this doesn't work on Apple, missing definitions like
    #      TARGET_OS_IPHONE. it seems like these headers should be included using -isysroot,
    #      but (a) that doesn't seem to work, and (b) isn't that already done by the cmake
    #      toolchain file? work around the issue by inserting an include for the missing
    #      definitions at the top of the headers included from POCL's kernel library.
    sed -i '1s/^/#include <TargetConditionals.h>\n/' $sysroot_include/stdio.h
fi
sed -i "s|COMMENT \\"Building C to LLVM bitcode \${BC_FILE}\\"|\\"-I$sysroot_include\\"|" \
       cmake/bitcode_rules.cmake

# our version of MinGW is ancient (?) and lacks `_aligned_malloc`
sed -i 's/_aligned_malloc/__mingw_aligned_malloc/g' include/vccompat.hpp

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Don't build tests
CMAKE_FLAGS+=(-DENABLE_TESTS:Bool=OFF)

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
if [[ "${target}" == *mingw* ]]; then
    # XXX: fake .exe binaries so CMake finds them (PoCL isn't good at cross-compilation)
    for tool in clang clang++ llvm-as llvm-dis llvm-link opt llc lli; do
        ln -s /opt/$MACHTYPE/bin/$tool /opt/$MACHTYPE/bin/$tool.exe
    done
fi

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

# XXX: work around pocl#1776, disabling FP16 support in i686
if [[ ${target} == *-freebsd* ]]; then
    CMAKE_FLAGS+=(-DHOST_COMPILER_SUPPORTS_FLOAT16:BOOL=OFF)
fi

# Link LLVM statically so that we don't have to worry about versioning the JLL against it
CMAKE_FLAGS+=(-DSTATIC_LLVM:Bool=ON)
# XXX: we add -pthread to the flags used to link libLLVM, so need that here too
#      (as that is not reflected by llvm-config)
CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-pthread")

# Force use of the SPIRV LLVM translator library by nuking the executable variant
CMAKE_FLAGS+=(-DLLVM_SPIRV="")
if [[ "${target}" == *-mingw* ]]; then
    # PoCL looks for LLVMSPIRVLib in the LLVM libdir, which on Windows contains static libs.
    # XXX: fix this upstream
    CMAKE_FLAGS+=(-DLLVM_SPIRV_INCLUDEDIR="${prefix}/include/LLVMSPIRVLib")
    CMAKE_FLAGS+=(-DLLVM_SPIRV_LIB="${prefix}/bin/libLLVMSPIRVLib.dll")
fi

# PoCL's CPU autodetection doesn't work on RISC-V
if [[ ${target} == riscv64-* ]]; then
    CMAKE_FLAGS+=(-DLLC_HOST_CPU=rv64gc)
    # forcing a CPU disables distro kernellib mode, so only provide a native build
    CMAKE_FLAGS+=(-DKERNELLIB_HOST_CPU_VARIANTS=native)
fi

# XXX: PoCL defaults to not using shared libraries on MinGW -- this seems to work fine?
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install

# PoCL uses Clang, which relies on certain system libraries Clang_jll.jl doesn't provide
mkdir -p $prefix/share/lib
if [[ ${target} == *-linux-gnu ]]; then
    if [[ ${target} == riscv64-* ]]; then
        cp -a $sysroot/lib64/lp64d/libc.* $prefix/share/lib
        cp -a $sysroot/usr/lib64/lp64d/libm.* $prefix/share/lib
        ln -sf libm.so.6 $prefix/share/lib/libm.so
        cp -a $sysroot/lib64/lp64d/libm.* $prefix/share/lib
        cp -a /opt/${target}/${target}/lib/libgcc_s.* $prefix/share/lib
        cp -a /opt/$target/lib/gcc/$target/*/*.{o,a} $prefix/share/lib
    elif [[ "${nbits}" == 64 ]]; then
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

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
## we don't build LLVM 15+ for i686-linux-musl.
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)

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

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   [build.platform], products, dependencies;
                   build.preferred_gcc_version, preferred_llvm_version=v"20",
                   julia_compat="1.6", init_block)
end
