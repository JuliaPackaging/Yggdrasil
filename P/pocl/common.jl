#=

Shared build logic for the PoCL 7.2 JLLs (`pocl_next` and `pocl_standalone`).

This is the 7.2 track of PoCL. The goal is a JLL that needs *no* run-time helper tooling:
no wrapper scripts, no bundled startup files, no external clang/lld/llvm-spirv. The init
block does nothing but (for the ICD build) register the driver.

Two upstream/build changes make that possible:

1. JIT (upstream PR #2190): CPU host kernels are loaded in-process via LLVM ORC/JITLink
   instead of being compiled to a shared object and dlopen()ed. JITLink is both the
   linker and the loader, so there is no external link step:

     - no `lld` invocation       -> no LLD wrapper, no LLD_unified_jll
     - no Clang driver link step -> no Clang wrapper (the frontend runs in-process via
                                    libclang, and codegen emits the object in-process)
     - no startup files / libc   -> the JIT resolves libc/libm/compiler-rt via normal
       / libgcc to bundle           process-symbol lookup, so we drop the `share/lib`
                                    staging the 7.1 recipe needed for the external link

   We also build without the Level Zero driver (`-DENABLE_LEVEL0=OFF`), the only consumer
   of `spirv-link`, so SPIRV_Tools_jll goes away too.

2. SPIR-V via the translator *library*, vendored. PoCL converts SPIR-V <-> LLVM IR with
   the SPIRV-LLVM-Translator. Using its `llvm-spirv` *binary* would mean shipping it and
   wrapping it (to set up its library path) at run time. Instead we build the translator
   here as a static library and link it into libpocl. The catch (which bit us before, on
   macOS especially) is that the translator API passes `llvm::Module`s across the ABI
   boundary, so it must share a *single* LLVM with PoCL -- two LLVM copies means two sets
   of global state / type uniquing and is undefined behavior. We therefore build the
   translator against the *same* LLVM_full_jll and link it statically against LLVM's
   component libraries (DISABLE_LLVM_LINK_LLVM_DYLIB), so libLLVMSPIRVLib.a carries only
   translator objects whose LLVM references resolve against PoCL's own statically-linked
   LLVM at the final link. One LLVM copy, ODR-safe, and no SPIRV_LLVM_Translator_jll.

The `standalone` argument selects between two variants of this same build:

- standalone=false (`pocl_next`): an OpenCL ICD driver (ENABLE_ICD=ON) loaded by an ICD
  loader; the init block registers it with OpenCL_jll.
- standalone=true (`pocl_standalone`): a directly-linkable library (ENABLE_ICD=OFF) whose
  OpenCL entrypoints are renamed to `PO<cl_function>` (RENAME_POCL), so it can be used as
  a CPU back-end (e.g. by KernelAbstractions.jl's nanoOpenCL) without an OpenCL.jl/ICD
  dependency while coexisting in-process with a real OpenCL ICD targeting other GPUs.

The stable 7.1 `pocl` recipe is intentionally *not* built from here: its 7.1 build system
and external-link/wrapper machinery differ enough that it carries its own self-contained
build script.

=#

function build_script(standalone=false)
    preheader = """
    STANDALONE=$(standalone)
    LLVM_MAJOR_MINOR=$(llvm_version.major).$(llvm_version.minor)
    MACOS_SDK_VERSION=$(macos_sdk_version)
    """

    script = preheader * raw"""
    # macOS SDK setup, shared by both the translator and PoCL builds below (it redirects
    # the toolchain, so it must run before either of them).
    if [[ "${target}" == x86_64-apple-darwin* ]]; then
        # Use the SDK matching the selected LLVM build.
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
        tar --extract --file=$WORKSPACE/srcdir/MacOSX${MACOS_SDK_VERSION}.sdk.tar.xz \
            --directory=$WORKSPACE/srcdir --warning=no-unknown-keyword \
            MacOSX${MACOS_SDK_VERSION}.sdk/System MacOSX${MACOS_SDK_VERSION}.sdk/usr
        rm -rf $apple_sysroot/System
        cp -ra $WORKSPACE/srcdir/MacOSX${MACOS_SDK_VERSION}.sdk/usr/* $apple_sysroot/usr/.
        cp -ra $WORKSPACE/srcdir/MacOSX${MACOS_SDK_VERSION}.sdk/System $apple_sysroot/.
        # redirect every sys-root reference (--sysroot and -isysroot) at it
        sed -i "s!/opt/${target}/${target}/sys-root!$apple_sysroot!g" ${CMAKE_TARGET_TOOLCHAIN}
        sed -i "s!/opt/${target}/${target}/sys-root!$apple_sysroot!g" /opt/bin/${bb_full_target}/${target}-clang*
        export MACOSX_DEPLOYMENT_TARGET=${MACOS_SDK_VERSION}
    fi

    ##########################################################################
    # 1. Build the vendored SPIRV-LLVM-Translator as a static library.
    #
    # Built against the same LLVM_full_jll as PoCL and linked statically against
    # LLVM's component libs (DISABLE_LLVM_LINK_LLVM_DYLIB), so libLLVMSPIRVLib.a
    # contains only translator objects; their LLVM references resolve against
    # PoCL's own static LLVM at the final libpocl link (single LLVM, ODR-safe).
    ##########################################################################
    # BB's cmake toolchain pins CMAKE_INSTALL_PREFIX to ${prefix}, so the translator
    # installs there -- conveniently right where PoCL's SetupLLVMSPIRV.cmake looks
    # (LLVM_INCLUDE_DIRS / LLVM_LIBDIR). We link it into libpocl below and then delete
    # its artifacts from ${prefix} at the end, so they don't ship in the JLL.
    spirv_src=$WORKSPACE/srcdir/SPIRV-LLVM-Translator
    pushd $spirv_src
    install_license LICENSE.TXT
    # LLVM 20's translator needs this backport.  It is already present in the
    # LLVM 22.1 translator, where applying it with fuzz targets unrelated code.
    if [[ "${LLVM_MAJOR_MINOR}" == 20.* ]]; then
        atomic_patch -p1 $WORKSPACE/srcdir/patches/spirv-translator-addrspacecast_null.patch
    fi
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
    SPIRV_CMAKE_FLAGS+=(-DBASE_LLVM_VERSION=${LLVM_MAJOR_MINOR})
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
    # LLVM 22 split DTLTO out of LLVMLTO. PoCL's static component list predates
    # that split, leaving lld's llvm::lto::DTLTO vtable unresolved at load time.
    sed -i '/  LLVMLTO/a\  LLVMDTLTO' cmake/SetupLLVMviaCMake.cmake

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
        # Build PoCL with the Clang/lld toolchain on Windows; GNU ld is pathologically slow
        # at producing a PE/COFF DLL from the large static LLVM/Clang archives (see the
        # export-model notes above). Mirrors what the SPIR-V translator already uses.
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
    else
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
    fi
    CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)

    # PoCL 7.2 looks for the *host* LLVM tools (clang, opt, llc, ...) in the directory
    # of the llvm-config we pass (LLVM_CONFIG_LOCATION), whereas 7.1 used LLVM_BINDIR.
    # Our llvm-config is a wrapper script living alone in srcdir, so assemble a bin dir
    # that holds it alongside symlinks to the native host LLVM tools, and point
    # WITH_LLVM_CONFIG there.
    llvm_host_bin=$WORKSPACE/srcdir/llvm-host-bin
    mkdir -p $llvm_host_bin
    cp $WORKSPACE/srcdir/llvm-config $llvm_host_bin/llvm-config
    chmod +x $llvm_host_bin/llvm-config
    for tool in clang clang++ opt llc llvm-as llvm-dis llvm-link; do
        ln -sf /opt/$MACHTYPE/bin/$tool $llvm_host_bin/$tool
        # on mingw targets CMake appends .exe when searching, so provide that name too
        # (the host tools are ELF binaries; the suffix is just what find_program looks for)
        ln -sf /opt/$MACHTYPE/bin/$tool $llvm_host_bin/$tool.exe
    done

    # Point to relevant LLVM tools (see above). The target-side dependencies live
    # under ${prefix} (which is a symlink to the per-target destdir).
    ## Target-side LLVM CMake package. PoCL 7.2 requires LLVM_DIR (the target
    ## LLVMConfig.cmake) *in addition* to the spoofed llvm-config when cross-compiling
    ## (cmake/LLVM.cmake); their major.minor versions must agree.
    CMAKE_FLAGS+=(-DLLVM_DIR=${prefix}/lib/cmake/llvm)
    ## HostDependency: llvm-config, but spoofed to return Dependency's paths
    CMAKE_FLAGS+=(-DWITH_LLVM_CONFIG=$llvm_host_bin/llvm-config)
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
        # Build PoCL as a dynamic library loaded by the OpenCL runtime.
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

    # Load CPU host kernels in-process via ORC/JITLink instead of Clang+dlopen.
    # This is the whole point of the 7.2 track: it removes the external link step
    # (no lld, no startup files, no clang driver invocation at run time).
    CMAKE_FLAGS+=(-DHOST_CPU_ENABLE_JIT:BOOL=ON)

    # PoCL bundles a libgcc archive so the JIT can resolve soft-float helpers (e.g. __truncdfhf2
    # for FP16), auto-detecting it via `${CMAKE_C_COMPILER} -print-libgcc-file-name`. That comes
    # up empty under our Windows clang, so point PoCL at the target GCC's libgcc.a explicitly
    # (same archive clang links against; has the helpers on GCC >= 12).
    if [[ "${target}" == *-mingw* ]]; then
        libgcc_archive=$(gcc -print-libgcc-file-name)
        if [[ ! -f "${libgcc_archive}" ]]; then
            echo "ERROR: could not locate libgcc.a for the CPU JIT (got '${libgcc_archive}')" >&2
            exit 1
        fi
        CMAKE_FLAGS+=(-DHOST_CPU_COMPILER_RT_LIBRARY_SOURCE=${libgcc_archive})
    fi

    # Build without the (experimental) Level Zero driver. It is the only consumer
    # of spirv-link, so disabling it lets us drop SPIRV_Tools_jll entirely.
    CMAKE_FLAGS+=(-DENABLE_LEVEL0:BOOL=OFF)

    # XXX: work around pocl#1776, disabling FP16 support for FreeBSD
    if [[ ${target} == *-freebsd* ]]; then
        CMAKE_FLAGS+=(-DHOST_COMPILER_SUPPORTS_FLOAT16:BOOL=OFF)
    fi

    # Vectorize OpenCL math builtins (sin/exp/log/...) via a vector-math library. This is
    # gated to exactly where it can work: LLVM's TargetLibraryInfo only maps a veclib for
    # x86_64 (libmvec ABI, _ZGVdN*) and aarch64 (SLEEF ABI, _ZGVnN*), and SLEEF_jll only ships
    # the symbol-providing libsleefgnuabi on ELF targets -- Linux and FreeBSD (NOT macOS, which
    # has no GNUABI variant on Mach-O, and NOT Windows, where SLEEF_jll isn't built). The
    # in-process JIT dlopens it by SONAME at run time, so nothing is redistributed beyond the
    # SLEEF_jll dependency (added per-platform in build_tarballs.jl). Elsewhere there's no
    # veclib -> the kernel body still vectorizes, transcendentals stay scalar. NB: on AVX-512
    # hosts the work-item loop tends to pick width 16, which LLVM's x86 veclib tables don't
    # cover (they stop at width 8), so the math scalarizes there; AVX2 (width 8) and aarch64
    # NEON (width 4) get packed _ZGV* calls. (Separate from the always-on SLEEF kernel library,
    # ENABLE_SLEEF.)
    sleef_gnuabi="${prefix}/lib/libsleefgnuabi.so"
    if [[ "${target}" == x86_64-linux-* || "${target}" == x86_64-*freebsd* ]]; then
        CMAKE_FLAGS+=(-DENABLE_HOST_CPU_VECTORIZE_LIBMVEC:BOOL=ON)
        CMAKE_FLAGS+=(-DLIBMVEC="${sleef_gnuabi}")
        # libsleefgnuabi exports the required _ZGV* symbols; skip the (cross-unfriendly) probe.
        CMAKE_FLAGS+=(-DLIBMVEC_HAS_REQUIRED_SYMBOLS:BOOL=ON)
    elif [[ "${target}" == aarch64-linux-* || "${target}" == aarch64-*freebsd* ]]; then
        CMAKE_FLAGS+=(-DENABLE_HOST_CPU_VECTORIZE_SLEEF:BOOL=ON)
        CMAKE_FLAGS+=(-DLIBSLEEF="${sleef_gnuabi}")
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

    # Our sysroot ships an old glibc whose <inttypes.h> only defines the PRI* format
    # macros for C++ when __STDC_FORMAT_MACROS is set. PoCL's C++ sources include LLVM
    # headers (which pull <inttypes.h>) before pocl_debug.h, so pocl_debug.h's own
    # late `#define __STDC_FORMAT_MACROS` is too late (the include guard is already set)
    # and PRId64/PRIu64 end up undefined (e.g. pocl_llvm_utils.cc's "Created context %"
    # PRId64). Define it on the command line so it's set before the first include.
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-D__STDC_FORMAT_MACROS")

    # Enable SPIR-V support via the vendored translator *library* (built above), linked
    # statically into libpocl. Pre-seed the cache vars SetupLLVMSPIRV.cmake would otherwise
    # search for, so it uses our copy and enables HAVE_LLVM_SPIRV_LIB. We do NOT set any
    # llvm-spirv binary path, so the binary code path stays off and no wrapper is needed.
    CMAKE_FLAGS+=(-DLLVM_SPIRV_INCLUDEDIR=${spirv_inc})
    CMAKE_FLAGS+=(-DLLVM_SPIRV_LIB=${spirv_lib})

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
    """

    return script
end

function init_block(standalone=false)
    if standalone
        # The standalone build is linked directly rather than loaded through an OpenCL ICD
        # loader, so it has no driver to register (and no OpenCL_jll dependency). And because
        # CPU host kernels are loaded in-process via the JIT (no external clang/lld/spirv-link),
        # there are no tools to locate at run time either -- so there is nothing to initialize.
        raw"""
        # Nothing to initialize: the standalone JIT build is fully self-contained
        # (no ICD driver to register, no external tools to locate).
        """
    else
        # No wrappers, no environment hacks: the JIT build links everything it needs
        # (LLVM, clang, the SPIR-V translator) statically into libpocl, so there are no
        # external tools to locate at run time. We only register the driver with the loader.
        raw"""
        # Register this driver with OpenCL_jll
        if OpenCL_jll.is_available()
            push!(OpenCL_jll.drivers, libpocl)
        end
        """
    end
end
