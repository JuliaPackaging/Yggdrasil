const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

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
script_common = raw"""
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
# Statically link against LLVM
CMAKE_FLAGS+=(-DSTATIC_LLVM:Bool=On)
# Generate a portable build
CMAKE_FLAGS+=(-DKERNELLIB_HOST_CPU_VARIANTS=distro)
# Build POCL as an dynamic library loaded by the OpenCL runtime
CMAKE_FLAGS+=(-DENABLE_ICD:BOOL=ON)
# XXX: work around pocl#1528, disabling FP16 support in i686
if [[ ${target} == i686-* ]]; then
    CMAKE_FLAGS+=(-DHOST_CPU_SUPPORTS_FLOAT16:BOOL=OFF)
fi
if [[ ${STANDALONE} ]]; then
    CMAKE_FLAGS+=(-DENABLE_ICD:BOOL=OFF)
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
