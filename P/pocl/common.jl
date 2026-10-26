#=

Shared build logic for the PoCL 7.2 JLLs (`pocl`, `pocl_next`, `pocl_standalone` and
`pocl_standalone_next`).

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

- standalone=false (`pocl`, `pocl_next`): an OpenCL ICD driver (ENABLE_ICD=ON) loaded by an ICD
  loader; the init block registers it with OpenCL_jll.
- standalone=true (`pocl_standalone`, `pocl_standalone_next`): a directly-linkable library
  (ENABLE_ICD=OFF) whose OpenCL entrypoints are renamed to `PO<cl_function>` (RENAME_POCL),
  so it can be used as a CPU back-end (e.g. by KernelAbstractions.jl's nanoOpenCL) without
  an OpenCL.jl/ICD dependency while coexisting in-process with a real OpenCL ICD targeting
  other GPUs.

The recipes differ in their sources: `pocl` is the release track (upstream v7.2 plus its
own patch series), while the others follow upstream's 7.2 maintenance branch with the
series in `pocl_next/bundled` (`pocl_standalone/bundled` is a symlink to it, and
`pocl_standalone_next` uses it directly, so changing that series needs a change to their
recipes to trigger their rebuild).

The `spirv32` keyword additionally applies the experimental series in
`pocl_next/bundled/patches/pocl-spirv32`, which enables SPIR-V on 32-bit x86 (maleadt/pocl#2).
`pocl_next` and `pocl_standalone_next` opt in, so that it can be tested before it moves into
the default series; without it, the build script is the same as before.

=#

function build_script(standalone=false; spirv32=false)
    # The patch series to apply (and to hash into the version), in order; see the list in
    # the script below. `pocl-spirv32` (maleadt/pocl#2) follows the default series: a
    # generated SPIR wrapper for the i386 ABI, struct types in SPIR modules that keep their
    # OpenCL C layout instead of the host's (where long and double are less aligned), tests,
    # and enabling SPIR-V on 32-bit x86 CPU hosts. It's kept out of the script's comments so
    # that the script doesn't change for the recipes that don't opt in.
    patches = raw"$WORKSPACE/srcdir/patches/pocl/*.patch"
    if spirv32
        patches *= raw" $WORKSPACE/srcdir/patches/pocl-spirv32/*.patch"
    end

    preheader = """
    STANDALONE=$(standalone)
    LLVM_MAJOR_MINOR=$(llvm_version.major).$(llvm_version.minor)
    """

    script = preheader * raw"""
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

    # Apply our patch series (`git format-patch` exports; the binary SPIR-V test inputs are
    # excluded since we don't build the tests). `pocl` applies its series to upstream v7.2;
    # `pocl_next` and `pocl_standalone` apply theirs to upstream's 7.2 maintenance branch
    # (release_next), which already contains the release series' backports of upstream PRs
    # #2239, #2305, #2322, #2349, #2361, #2381 and #2397.
    #
    # The `pocl_next` series:
    # - 0001: MinGW Clang/lld toolchain support (JuliaGPU-only, not upstreamed)
    # - 0002: FP16 host math overloads (upstream PR #2224, in `main`)
    # - 0003: in-process JIT via ORC/JITLink (upstream PR #2190, in `main`)
    # - 0004, 0005: CanonicalizeBarriers fix for reconverging barrier successors (upstream
    #   PR #2281, closed: upstream won't change the legacy work-item loops)
    # - 0006, 0007: UnreachablesToReturns fix for issue #1958 (upstream PR #2280, in `main`)
    # - 0008, 0009: keep LLVM from replacing the host's SIGSEGV/SIGBUS handlers, which kills
    #   Julia's GC safepoints (upstream PRs #2339, #2340, in `main`; JuliaGPU/OpenCL.jl#487)
    # - 0010: keep UnreachablesToReturns from deleting the entry block of a kernel reduced to
    #   `unreachable` (upstream PR #2346, in `main`; JuliaGPU/OpenCL.jl#509)
    # - 0011: keep WorkitemLoops from rematerializing allocas without an initializer store
    #   (upstream PR #2345; JuliaGPU/OpenCL.jl#510)
    # - 0012: keep frexp on libclc when vectorizing builtins, avoiding a vector llvm.frexp
    #   miscompile on x86 below AVX2 (upstream PR #2359; JuliaGPU/OpenCL.jl#506)
    # - 0013, 0014: only wake up the CPU worker threads a command can use, making small
    #   kernel launches and subdevices cheap (upstream PR #2371, in `main`)
    # - 0015, 0016: create the CPU worker threads with an 8 MiB stack, which was intended but
    #   never took effect (512 KiB on macOS, 1-2 MiB on Windows) (upstream PR #2383)
    # - 0017: estimate kernel stack use after SROA, so that the -O0 locals of builtins like
    #   hypot don't lower CL_KERNEL_WORK_GROUP_SIZE (upstream PR #2384)
    # - 0018: build the FP16 builtins without double-precision helpers, whose
    #   llvm.roundeven lowers to a roundeven libcall missing on Windows below SSE4.1
    #   (upstream commit 7fd676ef1, in `main`; JuliaGPU/OpenCL.jl#539)
    # - 0019: accept SPIR-V using SPV_INTEL_subgroups again, lost in 7.2, for vector sub-group
    #   shuffles (upstream PR #2394, in `main`; JuliaGPU/KernelAbstractions.jl#864)
    # - 0020: also pass the SPIR wrapper's --mingw flag for our unnormalized mingw32
    #   LLC_TRIPLE (on top of upstream PR #2381; JuliaGPU-only)
    # - 0021: convert half printf arguments in software instead of through _Float16, whose
    #   libgcc helpers need libgcc_s >= GCC 12 and kept libpocl from loading next to an older
    #   system libgcc_s, e.g. under `nsys profile` (upstream PR #2403, whose latest revision
    #   relies on a rewrite of pocl_half_to_float that 7.2 doesn't have, so with a local
    #   decoder)
    # - 0022: keep CPU worker threads that are going to sleep from missing their wake-up
    #   signal, which 0014 made possible and which slowly shrank the pool to a few threads
    #   (upstream PR #2386)
    # - 0023, 0024: fail commands whose wait-list dependency had already failed instead of
    #   running them, which could crash a worker thread (upstream PR #2214, in `main`)
    # - 0025: report the error when clCreateBuffer can't register a buffer's device address,
    #   instead of returning NULL with CL_SUCCESS (upstream PR #2376)
    # - 0026: fill system SVM pointers (e.g. malloc'd memory) in clEnqueueSVMMemFill and
    #   clEnqueueMemFillINTEL directly instead of crashing on their missing shadow buffer
    #   (upstream PR #2378; JuliaGPU/OpenCL.jl#536)
    # - 0027: return the binaries of programs that haven't been built from clGetProgramInfo
    #   (upstream PR #2379, in `main`; JuliaGPU/OpenCL.jl#537)
    # - 0028: link kernels against the vector-math library loaded at run time rather than its
    #   configure-time path in the build sandbox, which made every kernel link fail without the
    #   JIT and exported binaries lack native code (upstream PR #2380; JuliaGPU/OpenCL.jl#540)
    # - 0029: return NaN from FP16 powr for 1^inf, 0^0 and inf^0 (upstream commit ed1a18051,
    #   in `main`)
    # - 0030: use the CORE-math rsqrt for FP16, as 1/sqrt isn't accurate enough (upstream
    #   commit 154ffcace, in `main`)
    # - 0031-0033: implement clEnqueueWaitForEvents, a stub returning CL_INVALID_OPERATION, by
    #   forwarding to clEnqueueBarrierWithWaitList (upstream PR #2377, in `main`, without its
    #   remote and CUDA driver commits; JuliaGPU/OpenCL.jl#538)
    # - 0034: pass group ids to work-group functions as size_t instead of ulong, which is 32
    #   bits on 64-bit Windows and left the high half of group_z uninitialized (upstream PR
    #   #2410, in `main`)
    # - 0035: keep VariableUniformityAnalysis from reusing the cached uniformity of a deleted
    #   value for a new one allocated at its address, which intermittently miscompiled
    #   work-item dependent values as uniform (upstream PR #2414)
    # - 0036: remove the SIGFPE handler, which replaced the host application's handler and only
    #   covered PoCL's own threads; integer division is made safe by SanitizeUBofDivRem
    #   instead (upstream PR #2350, in `main`)
    # - 0037: initialize program-scope variables once per program and device, also for
    #   programs whose binaries were queried before a launch or that were rebuilt (upstream
    #   PR #2407)
    # - 0038: account for the z extent and the global offset when choosing the small-grid
    #   work-group function (upstream PR #2408)
    # - 0039: the draft cl_pocl_host_kernel extension, which lets KernelAbstractions.jl run
    #   kernels on Julia's threads (maleadt/pocl#1; JuliaGPU/KernelAbstractions.jl#906)
    # - 0040: report the stack estimate as CL_KERNEL_PRIVATE_MEM_SIZE on CPUs, so that users of
    #   cl_pocl_host_kernel can tell whether a work-group fits on their stack (maleadt/pocl#1)
    #
    # The `pocl` series on v7.2 is the one this series was rebased from: 0001-0042 also carry
    # the backports that release_next has, and older revisions of upstream PRs #2281, #2384,
    # #2394 and #2410; 0043-0045 are 0036-0038 above. It doesn't have
    # cl_pocl_host_kernel.
    for patch in @PATCHES@; do
        atomic_patch -p1 $patch
    done

    # POCL wants a target sysroot for compiling the host kernellib (for `math.h` etc)
    sysroot=/opt/${target}/${target}/sys-root
    if [[ "${target}" == *apple* ]]; then
        # require_macos_sdk redirects SDKROOT on x86_64; on aarch64 it remains
        # BinaryBuilder's default SDK root.
        sysroot=${SDKROOT}
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

    # Tag the version with a hash of our patch series. The version seeds the kernel cache
    # key, so rebuilds with a different series don't reuse previously cached binaries, and
    # it lets users tell these builds apart from upstream ones that lack our patches.
    # (`\\"`, as `\"` in this raw string would reach the shell as a bare quote.)
    patches_hash=$(cat @PATCHES@ | sha256sum | cut -c1-12)
    sed -i "s/^set(VERSION_SUFFIX_FIXED_TEXT \\"\\")/set(VERSION_SUFFIX_FIXED_TEXT \\"~julia-${patches_hash}\\")/" CMakeLists.txt
    if ! grep -q "^set(VERSION_SUFFIX_FIXED_TEXT \\"~julia-${patches_hash}\\")" CMakeLists.txt; then
        echo "ERROR: failed to tag the PoCL version" >&2
        exit 1
    fi

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
    # work-group size can overflow the 8 MiB worker stack and crash. Enabling this
    # makes PoCL estimate the per-work-item stack usage and clamp the kernel's
    # reported CL_KERNEL_WORK_GROUP_SIZE accordingly, so launches fit (and
    # over-large ones are rejected with CL_INVALID_WORK_GROUP_SIZE) instead of
    # crashing. The estimate doesn't cover values that live across barriers.
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
        # PoCL passes this as the LLVM target CPU at run time, so it has to be a CPU name
        # rather than an ISA string like rv64gc (which LLVM rejects). sifive-u54 implements
        # exactly RV64GC, the baseline we build everything else for.
        CMAKE_FLAGS+=(-DLLC_HOST_CPU=sifive-u54)
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

    return replace(script, "@PATCHES@" => patches)
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
