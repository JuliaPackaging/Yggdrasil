# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "pocl"
version = v"6.0"

# POCL supports LLVM 14 to 18
# XXX: link statically to a single version of LLVM instead, and don't use augmentations?
#      this causes issue with the compile-time link, so I haven't explored this yet
llvm_versions = [v"15.0.7", v"16.0.6", v"17.0.6"]

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    GitSource("https://github.com/pocl/pocl",
              "952bc559f790e5deb5ae48692c4a19619b53fcdc")
]

#=

POCL wants to be linked against LLVM for run-time code generation, but also generates code
at compile time using LLVM tools, so we need to carefully select which of the different
builds of LLVM we need:

- the Dependency one, in $prefix: everything we want, but can't use it during the build as
  its binaries aren't executable here (hopefully they will be with BinaryBuilder2.jl).
- the HostDependency one, in $host_prefix: can't emit code for the target, but provides an
  llvm-config returning the right flags. so we use it as the llvm-config during the build,
  spoofing the returned paths to the target ones.
- the native toolchain, at /opt/x86_64-linux-musl: supports the target, but can't link
  against it, and provides the wrong LLVM flags. so we only use its tools during the build
  by setting LLVM_BINDIR

=#

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pocl/
install_license LICENSE

# pocl#1517: fix compilation on FreeBSD
patch -p1 -i $WORKSPACE/srcdir/patches/freebsd.patch

# patches to improve portability, adding support for a generic kernel library
patch -p1 -i $WORKSPACE/srcdir/patches/distro.patch
patch -p1 -i $WORKSPACE/srcdir/patches/generic-cpu.patch

# POCL wants a target sysroot for compiling the host kernellib (for `math.h` etc)
sysroot=/opt/${target}/${target}/sys-root/usr/include
if [[ "${target}" == *apple* ]]; then
    # XXX: including the sysroot like this doesn't work on Apple, missing definitions like
    #      TARGET_OS_IPHONE. it seems like these headers should be included using -isysroot,
    #      but (a) that doesn't seem to work, and (b) isn't that already done by the cmake
    #      toolchain file? work around the issue by inserting an include for the missing
    #      definitions at the top of the headers included from POCL's kernel library.
    sed -i '1s/^/#include <TargetConditionals.h>\n/' $sysroot/stdio.h
fi
sed -i "s|COMMENT \\"Building C to LLVM bitcode \${BC_FILE}\\"|\\"-I$sysroot\\"|" \
       cmake/bitcode_rules.cmake

CMAKE_FLAGS=()
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
# Point to the HostDependency's llvm-config, which has the right config (flags, mode, etc)
# (but spoof certain things, like replacing paths and library filenames)
CMAKE_FLAGS+=(-DWITH_LLVM_CONFIG=$WORKSPACE/srcdir/llvm-config)
# Point to the toolchain's binaries, which support emitting code for the target.
CMAKE_FLAGS+=(-DLLVM_BINDIR=/opt/x86_64-linux-musl/bin)
# Override the target and triple, which POCL takes from `llvm-config --host-target`
triple=$(clang -print-target-triple)
CMAKE_FLAGS+=(-DLLVM_HOST_TARGET=$triple)
CMAKE_FLAGS+=(-DLLC_TRIPLE=$triple)
# Override the auto-detected target CPU (which POCL takes from `llc --version`)
CPU=$(clang --print-supported-cpus 2>&1 | grep -P '\t' | head -n 1 | sed 's/\s//g')
CMAKE_FLAGS+=(-DLLC_HOST_CPU_AUTO=$CPU)
# Generate a portable build
CMAKE_FLAGS+=(-DLLC_HOST_CPU=GENERIC)
CMAKE_FLAGS+=(-DKERNELLIB_HOST_CPU_VARIANTS=distro)
# Build POCL as an dynamic library loaded by the OpenCL runtime
CMAKE_FLAGS+=(-DENABLE_ICD:BOOL=ON)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
## i686-musl doesn't have LLVM
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
## Windows support is unmaintained
filter!(!Sys.iswindows, platforms)


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

# determine exactly which tarballs we should build
builds = []
for llvm_version in llvm_versions, llvm_assertions in (false, #=true=#)
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
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, llvm_assertions)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies,
            platforms=[augmented_platform]
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
                   preferred_gcc_version=v"10", julia_compat="1.6",
                   augment_platform_block)
end

