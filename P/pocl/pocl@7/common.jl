function build_script(standalone=false)
    preheader = """
    STANDALONE=$(standalone)
    """

    # Bash recipe for building across all platforms
    script = preheader * raw"""
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

    # Disable build mode
    CMAKE_FLAGS+=(-DENABLE_POCL_BUILDING:Bool=OFF)

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

    if [[ "${STANDALONE}" == "true" ]]; then
        CMAKE_FLAGS+=(-DENABLE_ICD:BOOL=OFF)
    else
        # Build POCL as an dynamic library loaded by the OpenCL runtime
        CMAKE_FLAGS+=(-DENABLE_ICD:BOOL=ON)
    fi

    # XXX: work around pocl#1776, disabling FP16 support for FreeBSD
    if [[ ${target} == *-freebsd* ]]; then
        CMAKE_FLAGS+=(-DHOST_COMPILER_SUPPORTS_FLOAT16:BOOL=OFF)
    fi

    # Link LLVM statically so that we don't have to worry about versioning the JLL against it
    CMAKE_FLAGS+=(-DSTATIC_LLVM:Bool=ON)
    # XXX: we add -pthread to the flags used to link libLLVM, so need that here too
    #      (as that is not reflected by llvm-config)
    CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-pthread")

    # Enable SPIR-V support
    ## disable use of the translator library, because the API is not ODR safe on macOS
    ## when statically linking LLVM
    CMAKE_FLAGS+=(-DLLVM_SPIRV_LIB="")
    ## force use of the translator binary even if not executable during the build
    ## XXX: add and use a HostBuildDependency?
    sed -i '/unset(LLVM_SPIRV CACHE)/d' -i cmake/LLVM.cmake

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
    ENV["POCL_PATH_SPIRV_LINK"] =
        generate_wrapper_script("spirv_link", SPIRV_Tools_jll.spirv_link_path,
                                SPIRV_Tools_jll.LIBPATH[], SPIRV_Tools_jll.PATH[])
    ENV["POCL_PATH_CLANG"] =
        generate_wrapper_script("clang", Clang_unified_jll.clang_path,
                                Clang_unified_jll.LIBPATH[], Clang_unified_jll.PATH[])
    ENV["POCL_PATH_LLVM_SPIRV"] =
        generate_wrapper_script("llvm-spirv",
                                SPIRV_LLVM_Translator_jll.llvm_spirv_path,
                                SPIRV_LLVM_Translator_jll.LIBPATH[],
                                SPIRV_LLVM_Translator_jll.PATH[])
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
        return pocl_binaries
    else
        return opencl * pocl_binaries
    end
end
