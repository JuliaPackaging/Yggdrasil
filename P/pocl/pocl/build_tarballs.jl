# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "pocl"
version = v"7.1.3"
llvm_version = v"20.1.2"

# Build

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    GitSource("https://github.com/juliagpu/pocl",
              "21d408ea0adbfd59934d5720132c0e7f412af98e"),
    # vendored SPIR-V translator, built as a static library against our LLVM (see
    # the build script below); this commit is the LLVM-20.1-compatible revision (matches
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


# `pocl` is the stable 7.1 release of PoCL, and the odd one out: the `pocl_next` and
# `pocl_standalone` recipes share the 7.2 JIT build in ../common.jl, but 7.1's build system
# and its external-link/wrapper machinery differ enough that this recipe carries its own
# self-contained build script and init block (inlined below).

function build_script(standalone=false)
    preheader = """
    STANDALONE=$(standalone)
    """

    # Bash recipe for building across all platforms
    script = preheader * raw"""
    # macOS SDK setup, shared by both the translator and PoCL builds below (it redirects
    # the toolchain, so it must run before either of them).
    if [[ "${target}" == x86_64-apple-darwin* ]]; then
        # LLVM 20 was built against the macOS 10.14 SDK, so PoCL needs it too.
        # We can't upgrade the SDK in the real sys-root: it lives on a read-only
        # overlay lower layer where removing/replacing directories fails with
        # I/O errors, and merging the SDK on top hits symlink-vs-directory
        # conflicts. So assemble a combined sysroot in a writable scratch dir
        # and point the toolchain at it. The copy of the sys-root carries the
        # things the bare SDK lacks (the toolchain's C++ headers, the build-time
        # LLVM headers under usr/local), and in the scratch copy we can replace
        # System the usual way.
        apple_sysroot=$WORKSPACE/srcdir/sysroot
        cp -a /opt/${target}/${target}/sys-root $apple_sysroot
        tar --extract --file=$WORKSPACE/srcdir/MacOSX10.14.sdk.tar.xz \
            --directory=$WORKSPACE/srcdir --warning=no-unknown-keyword \
            MacOSX10.14.sdk/System MacOSX10.14.sdk/usr
        rm -rf $apple_sysroot/System
        cp -ra $WORKSPACE/srcdir/MacOSX10.14.sdk/usr/* $apple_sysroot/usr/.
        cp -ra $WORKSPACE/srcdir/MacOSX10.14.sdk/System $apple_sysroot/.
        # redirect every sys-root reference (--sysroot and -isysroot) at it
        sed -i "s!/opt/${target}/${target}/sys-root!$apple_sysroot!g" ${CMAKE_TARGET_TOOLCHAIN}
        sed -i "s!/opt/${target}/${target}/sys-root!$apple_sysroot!g" /opt/bin/${bb_full_target}/${target}-clang*
        export MACOSX_DEPLOYMENT_TARGET=10.14
    fi

    ##########################################################################
    # 1. Build the vendored SPIRV-LLVM-Translator as a static library.
    #
    # PoCL converts SPIR-V <-> LLVM IR with the SPIRV-LLVM-Translator. Using its
    # `llvm-spirv` *binary* would mean shipping it (SPIRV_LLVM_Translator_jll) and
    # wrapping it (to set up its library path) at run time. Instead we build the
    # translator here as a static library and link it into libpocl. The catch (which
    # bit us before, on macOS especially) is that the translator API passes
    # `llvm::Module`s across the ABI boundary, so it must share a *single* LLVM with
    # PoCL -- two LLVM copies means two sets of global state / type uniquing and is
    # undefined behavior. We therefore build the translator against the same
    # LLVM_full_jll and link it statically against LLVM's component libs
    # (DISABLE_LLVM_LINK_LLVM_DYLIB), so libLLVMSPIRVLib.a contains only translator
    # objects; their LLVM references resolve against PoCL's own statically-linked
    # LLVM at the final libpocl link (single LLVM, ODR-safe).
    ##########################################################################
    # BB's cmake toolchain pins CMAKE_INSTALL_PREFIX to ${prefix}, so the translator
    # installs there -- conveniently right where PoCL's cmake/LLVM.cmake looks
    # (LLVM_INCLUDE_DIRS / LLVM_LIBDIR). We link it into libpocl below and then delete
    # its artifacts from ${prefix} at the end, so they don't ship in the JLL.
    spirv_src=$WORKSPACE/srcdir/SPIRV-LLVM-Translator
    pushd $spirv_src
    install_license LICENSE.TXT
    atomic_patch -p1 $WORKSPACE/srcdir/patches/spirv-translator-addrspacecast_null.patch
    # link statically against LLVM's component libraries rather than the LLVM dylib.
    # Patch both the library and the llvm-spirv tool: otherwise the tool links *both*
    # the LLVM dylib import-lib and the static components, which is fatal on COFF/lld
    # (duplicate symbols). The tool is built by `ninja install` (and removed afterwards),
    # but its link must succeed for the install -- hence the lib+headers we actually use.
    sed -i '/add_llvm_library(/a DISABLE_LLVM_LINK_LLVM_DYLIB' lib/SPIRV/CMakeLists.txt
    sed -i '/add_llvm_tool(/a DISABLE_LLVM_LINK_LLVM_DYLIB' tools/llvm-spirv/CMakeLists.txt

    SPIRV_CMAKE_FLAGS=()
    SPIRV_CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
    SPIRV_CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
    if [[ "${target}" == *mingw* ]]; then
        # on Windows, we run into "multiple definition" errors when linking with gcc
        SPIRV_CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
        SPIRV_CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-pthread")
    else
        SPIRV_CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
    fi
    SPIRV_CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
    # the static lib is linked into the shared libpocl, so it must be PIC
    SPIRV_CMAKE_FLAGS+=(-DCMAKE_POSITION_INDEPENDENT_CODE=ON)
    SPIRV_CMAKE_FLAGS+=(-DLLVM_DIR=${prefix}/lib/cmake/llvm)
    SPIRV_CMAKE_FLAGS+=(-DBASE_LLVM_VERSION=20.1)
    SPIRV_CMAKE_FLAGS+=(-DLLVM_SPIRV_INCLUDE_TESTS=OFF)
    if [[ "${target}" == *-apple-darwin* ]]; then
        cmake -B build -S . -GNinja ${SPIRV_CMAKE_FLAGS[@]} \
            -DCMAKE_CXX_FLAGS="-Wno-error=enum-constexpr-conversion -include vector"
    else
        cmake -B build -S . -GNinja ${SPIRV_CMAKE_FLAGS[@]}
    fi
    ninja -C build -j ${nproc} install
    popd

    spirv_inc=${prefix}/include/LLVMSPIRVLib
    spirv_lib=${prefix}/lib/libLLVMSPIRVLib.a
    echo "Vendored SPIR-V translator: lib=${spirv_lib} include=${spirv_inc}"
    if [[ ! -f "${spirv_lib}" || ! -f "${spirv_inc}/LLVMSPIRVLib.h" ]]; then
        echo "ERROR: vendored translator library/headers not found" >&2
        exit 1
    fi
    # Derive the maximum supported SPIR-V version from the translator headers, like
    # PoCL >= 7.2 does. PoCL 7.1 instead derives it with a try_run, which cannot
    # execute when cross-compiling, so we pre-seed the result below.
    spirv_maxver_minor=$(grep -oE 'MaximumVersion = SPIRV_1_[0-9]+' ${spirv_inc}/LLVMSPIRVOpts.h | grep -oE '[0-9]+$')
    spirv_maxver=$((65536 + spirv_maxver_minor * 256))
    echo "Maximum SPIR-V version supported by the translator: ${spirv_maxver}"

    ##########################################################################
    # 2. Build PoCL.
    ##########################################################################
    cd $WORKSPACE/srcdir/pocl/
    install_license LICENSE

    # POCL wants a target sysroot for compiling the host kernellib (for `math.h` etc)
    sysroot=/opt/${target}/${target}/sys-root
    if [[ "${target}" == x86_64-apple-darwin* ]]; then
        # use the combined sysroot assembled above
        sysroot=$apple_sysroot
    fi
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

    # Disable build mode
    CMAKE_FLAGS+=(-DENABLE_POCL_BUILDING:Bool=OFF)

    # Don't build tests
    CMAKE_FLAGS+=(-DENABLE_TESTS:Bool=OFF)

    # Enable optional debug messages for debuggability
    CMAKE_FLAGS+=(-DPOCL_DEBUG_MESSAGES:Bool=ON)

    # Install things into $prefix
    CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

    # Explicitly use our cmake toolchain file and tell CMake we're cross-compiling.
    if [[ "${target}" == *mingw* ]]; then
        # Build PoCL with the Clang/lld toolchain on Windows. The default GCC toolchain
        # links with GNU ld, which is pathologically slow at producing a PE/COFF DLL out
        # of the large static LLVM/Clang archives: the final libpocl link took ~25 min and
        # CMake's LLVM/Clang link tests (try_compile against static LLVM) another ~13 min,
        # together dominating the ~45 min Windows build. Clang defaults to lld, which links
        # the same DLL in a fraction of the time; the link tests inherit the toolchain, so
        # the configure-time cost disappears too. Clang also matches the Clang-built
        # LLVM_full_jll and vendored translator, avoiding the GCC-vs-Clang COMDAT mismatch.
        # The COFF export model this needs -- dllexport the public API + --exclude-all-symbols
        # (lld can't --exclude-libs the static LLVM out of auto-export, which would overflow
        # the 64K PE export limit) -- lives in the pinned pocl commit, and it requires the
        # ENABLE_LOADABLE_DRIVERS=OFF set below.
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
    else
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
    fi
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

    # Each work-item's private memory is laid out on the worker thread's stack
    # and replicated across the work-group, so a private-heavy kernel at a large
    # work-group size can overflow the default thread stack (only 512 KB on
    # macOS, 1 MB on Windows) and crash. Enabling this makes PoCL estimate the
    # per-work-item stack usage and clamp the kernel's reported
    # CL_KERNEL_WORK_GROUP_SIZE accordingly, so launches fit (and over-large ones
    # are rejected with CL_INVALID_WORK_GROUP_SIZE) instead of segfaulting.
    CMAKE_FLAGS+=(-DHOST_CPU_ENABLE_STACK_SIZE_CHECK:Bool=ON)

    if [[ "${STANDALONE}" == "true" ]]; then
        # Build a directly-linkable library instead of an OpenCL ICD driver.
        CMAKE_FLAGS+=(-DENABLE_ICD:BOOL=OFF)
        # Rename PoCL's OpenCL entrypoints to PO<cl_function>, so the standalone library can
        # coexist in-process with a real OpenCL ICD loader (e.g. one targeting other GPUs).
        CMAKE_FLAGS+=(-DRENAME_POCL:BOOL=ON)
        # With ENABLE_ICD=OFF, PoCL names the library "OpenCL" (libOpenCL.so), which would
        # collide with the system ICD loader. Rename it so it ships as a distinct product.
        sed -i 's/set(POCL_LIBRARY_NAME "OpenCL")/set(POCL_LIBRARY_NAME "pocl_standalone")/' CMakeLists.txt
    else
        # Build POCL as an dynamic library loaded by the OpenCL runtime
        CMAKE_FLAGS+=(-DENABLE_ICD:BOOL=ON)
    fi

    # Link the CPU device drivers (basic, pthread) straight into libpocl on every platform
    # rather than building them as separately-dlopen'd modules. We ship a fixed CPU-only set,
    # so loadable modules add no capability; inlining keeps one self-contained library (no
    # runtime driver-DLL discovery), consistent across platforms. It is also *required* on
    # Windows, where libpocl is linked with lld and exports only its dllexport'd public API
    # (--exclude-all-symbols): loadable modules can't import libpocl's internal pocl_driver_*
    # ABI across that boundary. (For the standalone build it additionally avoids clashes, as
    # RENAME_POCL only renames the public API.)
    CMAKE_FLAGS+=(-DENABLE_LOADABLE_DRIVERS:BOOL=OFF)

    # XXX: work around pocl#1776, disabling FP16 support for FreeBSD
    if [[ ${target} == *-freebsd* ]]; then
        CMAKE_FLAGS+=(-DHOST_COMPILER_SUPPORTS_FLOAT16:BOOL=OFF)
    fi

    # Link LLVM statically so that we don't have to worry about versioning the JLL against it
    CMAKE_FLAGS+=(-DSTATIC_LLVM:Bool=ON)
    # XXX: we add -pthread to the flags used to link libLLVM, so need that here too
    #      (as that is not reflected by llvm-config)
    if [[ "${target}" == *mingw* ]]; then
        # PoCL is built with the Clang/lld toolchain on Windows (see above). Add -pthread to
        # every link mode (not just executables): it pulls in libwinpthread, which Clang's
        # windows-gnu driver -- unlike GCC's -- does not link implicitly, and it matches the
        # -pthread we use when linking libLLVM (not reflected by llvm-config). Keep
        # --allow-multiple-definition as a guard against duplicate COMDAT/weak template
        # instantiations across the statically-linked LLVM/Clang/translator archives.
        CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-pthread -Wl,--allow-multiple-definition")
        CMAKE_FLAGS+=(-DCMAKE_SHARED_LINKER_FLAGS="-pthread -Wl,--allow-multiple-definition")
        CMAKE_FLAGS+=(-DCMAKE_MODULE_LINKER_FLAGS="-pthread -Wl,--allow-multiple-definition")
    else
        CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-pthread")
    fi

    # Enable SPIR-V support via the vendored translator *library* (built above), linked
    # statically into libpocl (the macOS ODR hazard that previously forced the binary
    # path is gone now that the translator shares PoCL's static LLVM, whose symbols are
    # hidden on macOS via -hidden-l). Pre-seed the cache variables cmake/LLVM.cmake
    # would otherwise probe: the lib/include paths it searches for, and the
    # HAVE/MAXVER results it would derive from a try_run (which cannot execute when
    # cross-compiling). We do NOT provide an llvm-spirv binary, so the binary code
    # path stays off and no run-time translator package or wrapper is needed.
    CMAKE_FLAGS+=(-DLLVM_SPIRV_INCLUDEDIR=${spirv_inc})
    CMAKE_FLAGS+=(-DLLVM_SPIRV_LIB=${spirv_lib})
    CMAKE_FLAGS+=(-DHAVE_LLVM_SPIRV_LIB:BOOL=ON)
    CMAKE_FLAGS+=(-DLLVM_SPIRV_LIB_MAXVER=${spirv_maxver})

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

    # The vendored translator is now statically linked into libpocl; remove its build
    # artifacts (static lib, generated headers, pkg-config, the unused llvm-spirv binary)
    # from the prefix so they don't ship in the JLL.
    rm -rf ${prefix}/include/LLVMSPIRVLib
    rm -f ${prefix}/lib/libLLVMSPIRVLib.a \
          ${prefix}/lib/pkgconfig/LLVMSPIRVLib.pc \
          ${prefix}/bin/llvm-spirv ${prefix}/bin/llvm-spirv.exe

    # PoCL uses Clang, which relies on certain system libraries Clang_jll.jl doesn't provide
    mkdir -p $prefix/share/lib
    if [[ ${target} == *-linux-gnu ]]; then
        if [[ ${target} == riscv64-* ]]; then
            cp -va $sysroot/lib64/lp64d/libc.* $prefix/share/lib
            cp -va $sysroot/usr/lib64/lp64d/libm.* $prefix/share/lib
            ln -vsf libm.so.6 $prefix/share/lib/libm.so
            cp -va $sysroot/lib64/lp64d/libm.* $prefix/share/lib
            cp -va /opt/${target}/${target}/lib/libgcc_s.* $prefix/share/lib
        elif [[ "${nbits}" == 64 ]]; then
            cp -va $sysroot/lib64/libc{.,-}* $prefix/share/lib
            cp -va $sysroot/usr/lib64/libm.* $prefix/share/lib
            ln -vsf libm.so.6 $prefix/share/lib/libm.so
            cp -va $sysroot/lib64/libm{.,-}* $prefix/share/lib
            cp -va /opt/${target}/${target}/lib64/libgcc_s.* $prefix/share/lib
        else
            cp -va $sysroot/lib/libc{.,-}* $prefix/share/lib
            cp -va $sysroot/usr/lib/libm.* $prefix/share/lib
            ln -vsf libm.so.6 $prefix/share/lib/libm.so
            cp -va $sysroot/lib/libm{.,-}* $prefix/share/lib
            cp -va /opt/${target}/${target}/lib/libgcc_s.* $prefix/share/lib
        fi
        cp -va /opt/$target/lib/gcc/$target/*/*.{o,a} $prefix/share/lib
    elif [[ ${target} == *-linux-musl ]]; then
        cp -va $sysroot/usr/lib/*.{o,a} $prefix/share/lib
        cp -va /opt/$target/lib/gcc/$target/*/*.{o,a} $prefix/share/lib
    elif [[ "${target}" == *-mingw* ]]; then
        cp -va $sysroot/lib/*.o $prefix/share/lib
        cp -va $sysroot/lib/libmsvcrt*.a $prefix/share/lib
        cp -va $sysroot/lib/libucrt*.a $prefix/share/lib
        cp -va $sysroot/lib/libm.a $prefix/share/lib
        cp -va $sysroot/lib/lib{kernel,user,shell}32.a $prefix/share/lib
        cp -va $sysroot/lib/libmingw*.a $prefix/share/lib
        cp -va $sysroot/lib/libmoldname.a $prefix/share/lib
        cp -va $sysroot/lib/libadvapi32.a $prefix/share/lib
        cp -va /opt/${target}/${target}/lib/libgcc* $prefix/share/lib
        cp -va /opt/$target/lib/gcc/$target/*/*.{o,a} $prefix/share/lib
    elif [[ "${target}" == *-apple-darwin* ]]; then
        cp -va $sysroot/usr/lib/crt1.o $prefix/share/lib
        cp -va $sysroot/usr/lib/libSystem.*tbd $prefix/share/lib
        cp -va $sysroot/usr/lib/libm.*tbd $prefix/share/lib
        cp -va $sysroot/usr/lib/libgcc_s.*tbd $prefix/share/lib
    fi
    """
end

function init_block(standalone=false)

    opencl = raw"""
    # Register this driver with OpenCL_jll
    if OpenCL_jll.is_available()
        push!(OpenCL_jll.drivers, libpocl)

        # XXX: Clang_jll does not have a functional clang binary on macOS,
        #      as it's configured without a default sdkroot (see #9221)
        if Sys.isapple()
            ENV["SDKROOT"] = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
        end
    end
    """

    # The standalone build is linked directly rather than loaded through an OpenCL ICD
    # loader, so it has no driver to register (and no OpenCL_jll dependency). It still uses
    # Clang_jll at run time to compile kernels, so it needs the same macOS SDK fix that the
    # regular build applies inside the OpenCL block above.
    macos_sdk = raw"""
    # XXX: Clang_jll does not have a functional clang binary on macOS,
    #      as it's configured without a default sdkroot (see #9221)
    if Sys.isapple()
        ENV["SDKROOT"] = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
    end
    """

    pocl_binaries = raw"""
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
        script = if Sys.isunix()
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
            joinpath(bindir, name)
        elseif Sys.iswindows()
            println(io, "@echo off")

            LIBPATH_base = get(ENV, LIBPATH_env, expanduser(LIBPATH_default))
            LIBPATH_value = if !isempty(LIBPATH_base)
                string(LIBPATH, pathsep, LIBPATH_base)
            else
                LIBPATH
            end
            println(io, "set \\"$LIBPATH_env=$LIBPATH_value\\"")

            println(io, "call \\"$path\\" %*")

            # XXX: on Windows, the Base.rename below often throws EBUSY, so include the PID
            joinpath(bindir, "$(name).$(getpid()).bat")
        else
            error("Unsupported platform")
        end
        close(io)

        # atomically move to the final location
        @static if VERSION >= v"1.12.0-DEV.1023"
            mv(temp_script, script; force=true)
        else
            Base.rename(temp_script, script, force=true)
        end

        return script
    end
    # NOTE: no spirv-link wrapper -- that tool (SPIRV_Tools_jll) is only used by the
    # Level Zero driver, which this CPU-only build does not enable (ENABLE_LEVEL0=OFF).
    ENV["POCL_PATH_CLANG"] =
        generate_wrapper_script("clang", Clang_unified_jll.clang_path,
                                Clang_unified_jll.LIBPATH[], Clang_unified_jll.PATH[])
    ld_path = if Sys.islinux()
            LLD_unified_jll.ld_lld_path
        elseif Sys.isapple()
            LLD_unified_jll.ld64_lld_path
        elseif Sys.iswindows()
            # PoCL doesn't use MSVC-style linker arguments, so still use the GNU ld wrapper.
            LLD_unified_jll.ld_lld_path
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
    if Sys.iswindows()
        # BUG: using native (backwards) slashes breaks Clang's --ld-path
        ld_wrapper = replace(ld_wrapper, '\\' => '/')
    end
    ENV["POCL_ARGS_CLANG"] = join([
            "-fuse-ld=lld", "--ld-path=$ld_wrapper",
            "-L", joinpath(artifact_dir, "share", "lib"),
            "-L", libdir
        ], ";")
    """

    if standalone
        return macos_sdk * pocl_binaries
    else
        return opencl * pocl_binaries
    end
end


# LLVM 20 was built against the macOS 10.14 SDK, so ship it. We only use the
# helper for the (centralized) SDK source; the install itself is done
# non-destructively in the build script below, which extracts the SDK to a scratch dir and
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
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    Dependency("OpenCL_jll"),
    Dependency("OpenCL_Headers_jll"),
    Dependency("Hwloc_jll"),
    Dependency("Zstd_jll"), # our LLVM 20 build has LLVM_ENABLE_ZSTD=ON
    # the SPIR-V translator is vendored and statically linked (see the build script
    # below), so SPIRV_LLVM_Translator_jll is no longer needed at run time. SPIRV_Tools_jll
    # (spirv-link) is not needed either: it is only consumed by the Level Zero driver, which
    # this CPU-only build does not enable.
    # clang + lld are invoked at run time to compile and link CPU kernels (the 7.1 series has
    # no in-process JIT), so these two are still required.
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
                   build.preferred_gcc_version,
                   preferred_llvm_version=Base.thismajor(llvm_version),
                   julia_compat="1.6", init_block=init_block())
end
