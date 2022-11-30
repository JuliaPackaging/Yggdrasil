# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include("../../fancy_toys.jl") # for get_addable_spec

# return the platforms supported by libjulia
function libjulia_platforms(julia_version)
    platforms = supported_platforms()

    # skip 32bit musl builds; they fail with this error:
    #    libunwind.so.8: undefined reference to `setcontext'
    filter!(p -> !(Sys.islinux(p) && libc(p) == "musl" && arch(p) == "i686"), platforms)

    if julia_version < v"1.7"
        # In Julia <= 1.6, skip macOS on ARM and Linux on armv6l
        filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)
        filter!(p -> arch(p) != "armv6l", platforms)
    end

    if julia_version == v"1.9.0" || julia_version == v"1.10.0"
        # 32bit ARM seems broken, see https://github.com/JuliaLang/julia/issues/47345
        filter!(p -> arch(p) != "armv6l", platforms)
        filter!(p -> arch(p) != "armv7l", platforms)
    end

    for p in platforms
        p["julia_version"] = string(julia_version)
    end

    # While the "official" Julia kernel ABI does not involve any C++ linker
    # symbols before Julia 1.6, `libjulia` exported "unofficial" symbols
    # dependent on the C++ strings ABI (coming from LLVM related code). This
    # doesn't matter if the client code is pure C, but as soon as there are
    # other (actual) C++ dependencies, we must make sure to use the matching C++
    # strings ABI. Hence we must use `expand_cxxstring_abis` below.
    #
    # In Julia >= 1.6, these C++ symbols all moved into `libjulia-internal`.
    if julia_version < v"1.6"
        platforms = expand_cxxstring_abis(platforms)
    end

    return platforms
end

# Collection of sources required to build Julia
function build_julia(ARGS, version::VersionNumber; jllversion=version)
    name = "libjulia"

    checksums = Dict(
        v"1.6.3" => "2593def8cc9ef81663d1c6bfb8addc3f10502dd9a1d5a559728316a11dea2594",
        v"1.7.0" => "8e870dbef71bc72469933317a1a18214fd1b4b12f1080784af7b2c56177efcb4",
        v"1.8.2" => "3e2cea35bf5df963ed7b75a83e8febfc000acf1e664ecd657a0772508eb1fb5d",
    )

    if version == v"1.9.0-DEV"
        sources = [
            GitSource("https://github.com/JuliaLang/julia.git", "0540f9d7394c0f0dc2690a57da914b33b636211c"),
            DirectorySource("./bundled"),
        ]
    elseif version == v"1.10.0-DEV"
        sources = [
            GitSource("https://github.com/JuliaLang/julia.git", "70bda2cfe4ba8d945ce23c014cd1c0e2b568ccc1"),
            DirectorySource("./bundled"),
        ]
    else
        sources = [
            ArchiveSource("https://github.com/JuliaLang/julia/releases/download/v$(version)/julia-$(version).tar.gz", checksums[version]),
            DirectorySource("./bundled"),
        ]

        if version == v"1.6.3"
            # WORKAROUND
            push!(sources, ArchiveSource("https://github.com/JuliaBinaryWrappers/LibOSXUnwind_jll.jl/releases/download/LibOSXUnwind-v0.0.7%2B0/LibOSXUnwind.v0.0.7.x86_64-apple-darwin.tar.gz",
                                         "e2ea6ecae13c0f2666d1b3020098feeab92affae1614f6b2a992dde0af88ec2f",
                                         unpack_target="LibOSXUnwind_jll"))
        end

    end

    # Bash recipe for building across all platforms
    script = raw"""
    apk add coreutils libuv-dev utf8proc

    # WORKAROUND for mingw: remove the fake `uname` binary, it throws off the
    # Julia buildsystem
    if [[ "${target}" == *mingw* ]]; then
      rm -f /usr/bin/uname
    fi

    cd $WORKSPACE/srcdir/julia*
    version=$(cat VERSION)
    # use the Julia version to determine the directory from which to read patches
    patchdir=$WORKSPACE/srcdir/patches/$version
    # Apply patches
    if [ -d $patchdir ]; then
    for f in $patchdir/*.patch; do
        echo "Applying path ${f}"
        atomic_patch -p1 ${f}
    done
    fi

    # HACK to allow building Julia 1.6 in Julia >= 1.7, as we can't install an old
    # LibOSXUnwind_jll for it (due to it becoming a stdlib in Julia 1.7).
    # See also <https://github.com/JuliaPackaging/Yggdrasil/pull/4320>
    if [[ "${target}" == *apple* ]] && [[ "${version}" == 1.6.* ]]; then
        cp $WORKSPACE/srcdir/LibOSXUnwind_jll/include/*.h ${includedir}
        mkdir -p ${includedir}/mach-o
        cp $WORKSPACE/srcdir/LibOSXUnwind_jll/include/mach-o/*.h ${includedir}/mach-o
        cp $WORKSPACE/srcdir/LibOSXUnwind_jll/lib/libosxunwind.* ${libdir}
    fi

    case ${target} in
        *linux*)
            OS=Linux
        ;;
        *mingw*)
            OS=WINNT
        ;;
        *darwin*)
            OS=Darwin
        ;;
        *freebsd*)
            OS=FreeBSD
        ;;
    esac

    cat << EOM >Make.host.user
    override CC=${CC_BUILD}
    override CXX=${CXX_BUILD}
    override AR=${AR_BUILD}
    USE_SYSTEM_LIBUV=1
    USE_SYSTEM_UTF8PROC=1
    # julia want's libuv.a
    override LIBUV=/usr/lib/libuv.so
    override LIBUTF8PROC=/usr/lib/libutf8proc.so.2

    override OS=Linux
    EOM

    # TODO: eventually we should get LLVM_CXXFLAGS from llvm-config from
    # a HostDependency, now that we have those
    LLVM_CXXFLAGS="-I${prefix}/include -fno-exceptions -fno-rtti -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS"
    if [[ "${version}" == 1.[0-5].* ]]; then
        LLVM_CXXFLAGS="${LLVM_CXXFLAGS} -std=c++11"
    else
        LLVM_CXXFLAGS="${LLVM_CXXFLAGS} -std=c++14"
    fi
    LLVM_LDFLAGS="-L${prefix}/lib"
    LDFLAGS="-L${prefix}/lib"
    CFLAGS="-I${prefix}/include"
    # -NDEBUG below fixes the FreeBSD build of Julia 1.4 and 1.5
    CXXFLAGS="-I${prefix}/include -DNDEBUG"
    if [[ "${target}" == *mingw* ]]; then
        if [[ "${version}" == 1.8.* ]]; then
            LLVMLINK="-L${prefix}/bin -lLLVM-13jl"
        elif [[ "${version}" == 1.9.* ]]; then
            LLVMLINK="-L${prefix}/bin -lLLVM-14jl"
        elif [[ "${version}" == 1.10.* ]]; then
            LLVMLINK="-L${prefix}/bin -lLLVM-14jl"
        else
            LLVMLINK="-L${prefix}/bin -lLLVM"
        fi
        LLVM_LDFLAGS="-L${prefix}/bin"
        LDFLAGS="-L${prefix}/bin"
    elif [[ "${target}" == *apple* ]]; then
        LLVMLINK="-L${prefix}/lib -lLLVM"
    else
        if [[ "${version}" == 1.6.* ]]; then
            LLVMLINK="-L${prefix}/lib -lLLVM-11jl"
        elif [[ "${version}" == 1.7.* ]]; then
            LLVMLINK="-L${prefix}/lib -lLLVM-12jl"
        elif [[ "${version}" == 1.8.* ]]; then
            LLVMLINK="-L${prefix}/lib -lLLVM-13jl"
        elif [[ "${version}" == 1.9.* ]]; then
            LLVMLINK="-L${prefix}/lib -lLLVM-14jl"
        elif [[ "${version}" == 1.10.* ]]; then
            LLVMLINK="-L${prefix}/lib -lLLVM-14jl"
        else
            echo "Error, LLVM version not specified"
            exit 1
        fi
    fi

    # enable extglob for BB_TRIPLET_LIBGFORTRAN_CXXABI
    shopt -s extglob

    # Strip the OS version from Darwin and FreeBSD
    BB_TRIPLET_LIBGFORTRAN_CXXABI=$(echo ${bb_full_target/-julia_version+([^-])} | sed 's/\(darwin\|freebsd\)[0-9.]*/\1/')

    cat << EOM >Make.user
    USE_SYSTEM_LLVM=1
    USE_SYSTEM_LLD=1
    USE_SYSTEM_LIBUNWIND=1

    USE_SYSTEM_PCRE=1
    USE_SYSTEM_OPENLIBM=1
    USE_SYSTEM_DSFMT=1
    USE_SYSTEM_GMP=1
    USE_SYSTEM_MPFR=1
    USE_SYSTEM_SUITESPARSE=1
    USE_SYSTEM_LIBUV=1
    USE_SYSTEM_UTF8PROC=1
    USE_SYSTEM_MBEDTLS=1
    USE_SYSTEM_LIBSSH2=1
    USE_SYSTEM_CURL=1
    USE_SYSTEM_LIBGIT2=1
    USE_SYSTEM_PATCHELF=1
    USE_SYSTEM_ZLIB=1
    USE_SYSTEM_P7ZIP=1

    override XC_HOST=${target}
    override OS=${OS}
    override BUILD_OS=Linux

    #llvm-config-host is not available
    override LLVMLINK=${LLVMLINK}    # For Julia <= 1.7
    override RT_LLVMLINK=${LLVMLINK} # For Julia >= 1.8
    override CG_LLVMLINK=${LLVMLINK} # For Julia >= 1.8
    override LLVM_CXXFLAGS=${LLVM_CXXFLAGS}
    override LLVM_LDFLAGS=${LLVM_LDFLAGS}

    # just nop this
    override LLVM_CONFIG_HOST=true

    # we only run flisp and we built that for Linux
    override spawn = \$(1)
    override cygpath_w = \$(1)

    # julia expects libuv-julia.a
    override LIBUV=${prefix}/lib/libuv.a

    override BB_TRIPLET_LIBGFORTRAN_CXXABI=${BB_TRIPLET_LIBGFORTRAN_CXXABI}
    override USE_BINARYBUILDER=1

    prefix=${prefix}
    LOCALBASE=${prefix}
    EOM

    # setting USE_SYSTEM_BLAS to get Julia to use OpenBLAS_jll doesn't work on macOS,
    # where the Julia build system instead tries to use a native BLAS, which however
    # then requires compiling a custom lapack, which fails for Julia 1.4
    if [[ "${target}" != *apple* ]]; then
        cat << EOM >>Make.user
        USE_SYSTEM_BLAS=1
        LIBBLASNAME=libopenblas
        USE_SYSTEM_LAPACK=1
        LIBLAPACKNAME=libopenblas
    EOM
    elif [[ "${version}" == 1.[0-6].* ]]; then
        cat << EOM >>Make.user
        USECLANG=1

        # link against libosxunwind, see https://github.com/JuliaPackaging/Yggdrasil/pull/2164
        # and https://github.com/JuliaPackaging/Yggdrasil/pull/2190
        LIBUNWIND:=-losxunwind
        JCPPFLAGS+=-DLIBOSXUNWIND
    EOM
    fi

    # avoid linker errors related to atomic support in 32bit ARM builds
    if [[ "${bb_full_target}" == armv7l-* ]]; then
        echo "MARCH=armv7-a" >>Make.user
    fi

    # Add file to one of the `STD_LIB_PATH`
    if [[ "${target}" == *mingw* ]]; then
        cp /opt/*-w64-mingw32/*-w64-mingw32/sys-root/bin/libwinpthread-1.dll /opt/*-w64-mingw32/*-mingw32/sys-root/lib/
    fi

    # first build flisp, as we need that for compilation; instruct the build system
    # to build it for the cross compilation host architecture, not the final target
    make BUILDING_HOST_TOOLS=1 NO_GIT=1 -j${nproc} VERBOSE=1 -C src/flisp host/flisp
    make clean -C src
    make clean -C src/support
    make clean -C src/flisp

    # We don't trust the system libm in places
    # So we include a private copy of libopenlibm
    mkdir -p usr/lib
    cp ${prefix}/*/libopenlibm.a usr/lib/

    # choose make targets which compile libjulia but don't try to build a sysimage
    if [[ "${version}" == 1.[0-5].* ]]; then
        MAKE_TARGET="julia-ui-release julia-ui-debug"
    else
        MAKE_TARGET="julia-src-release julia-cli-release julia-src-debug julia-cli-debug"
    fi

    # Start the actual build. We pass DSYMUTIL='true -ignore' to skip the
    # unnecessary step calling dsymutil, which in our cross compilation
    # environment results in a segfault.
    make USE_CROSS_FLISP=1 NO_GIT=1 LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" -j${nproc} VERBOSE=1 ${MAKE_TARGET} DSYMUTIL=true

    # HACK to avoid runtime dependency on LibOSXUnwind_jll with Julia 1.6: it
    # disables the `#include <libunwind.h>` statements in two header files,
    # and all code directly depending on them; luckily all of that is internal
    # and should not affect external code using the Julia kernel "API"
    if [[ "${version}" == 1.6.* ]]; then
        atomic_patch -p1 $WORKSPACE/srcdir/libunwind-julia-1.6.patch
    fi

    # 'manually' install libraries and headers
    mkdir -p ${libdir}
    mkdir -p ${includedir}/julia
    if [[ "${target}" == *mingw* ]]; then
        cp -r usr/bin/libjulia* ${bindir}/
    else
        cp -r usr/lib/libjulia* ${libdir}/
    fi

    cp -R -L usr/include/julia/* ${includedir}/julia
    install_license LICENSE.md
    """

    # HACK: JLLs are not allowed to use prerelease versions, so strip that out
    # e.g. for 1.7.0-beta2
    version = VersionNumber(version.major, version.minor, version.patch)

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = libjulia_platforms(version)

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libjulia", :libjulia; dont_dlopen=true),
        LibraryProduct("libjulia-debug", :libjulia_debug; dont_dlopen=true),
    ]

    # Dependencies that must be installed before this package can be built/used

    dependencies = BinaryBuilder.AbstractDependency[
        BuildDependency("OpenLibm_jll"),
        BuildDependency("dSFMT_jll"),
        BuildDependency("utf8proc_jll"),
        BuildDependency("MbedTLS_jll"),
        BuildDependency("LibSSH2_jll"),
        BuildDependency("LibCURL_jll"),
        BuildDependency("Zlib_jll"),
        BuildDependency("p7zip_jll"),
        BuildDependency("MPFR_jll"),
        BuildDependency("GMP_jll"),
        BuildDependency("Objconv_jll"),
        BuildDependency("SuiteSparse_jll"),
    ]

    # HACK: we can't install LLVM 12 JLLs for Julia 1.7 from within Julia 1.6. Similar
    # for several other standard JLLs.
    # So we use get_addable_spec below to "fake it" for now.
    # This means the resulting package has fewer dependencies declared, but at least it
    # will work and allow people to build JLL binaries ready for Julia 1.7
    if version.major == 1 && version.minor == 6
        push!(dependencies, Dependency("LibUV_jll"))
        push!(dependencies, Dependency("LibUnwind_jll"))
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_jll", v"11.0.1+3")))
        push!(dependencies, BuildDependency(get_addable_spec("OpenBLAS_jll", v"0.3.10+10")))
        push!(dependencies, BuildDependency(get_addable_spec("LibGit2_jll", v"1.2.3+0")))
    elseif version.major == 1 && version.minor == 7
        push!(dependencies, Dependency("LibUV_jll"))
        push!(dependencies, Dependency("LibUnwind_jll"; platforms=filter(!Sys.isapple, platforms)))
        push!(dependencies, Dependency(get_addable_spec("LLVMLibUnwind_jll", v"11.0.1+1"); platforms=filter(Sys.isapple, platforms)))
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_jll", v"12.0.1+3")))
    elseif version.major == 1 && version.minor == 8
        push!(dependencies, Dependency(get_addable_spec("LibUV_jll", v"2.0.1+11")))
        push!(dependencies, Dependency("LibUnwind_jll"; platforms=filter(!Sys.isapple, platforms)))
        push!(dependencies, Dependency(get_addable_spec("LLVMLibUnwind_jll", v"12.0.1+0"); platforms=filter(Sys.isapple, platforms)))
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_jll", v"13.0.1+3")))
    elseif version.major == 1 && version.minor == 9
        push!(dependencies, Dependency(get_addable_spec("LibUV_jll", v"2.0.1+11")))
        push!(dependencies, Dependency(get_addable_spec("LibUnwind_jll", v"1.5.0+4"); platforms=filter(!Sys.isapple, platforms)))
        push!(dependencies, Dependency(get_addable_spec("LLVMLibUnwind_jll", v"12.0.1+0"); platforms=filter(Sys.isapple, platforms)))
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_jll", v"14.0.6+0")))
    elseif version.major == 1 && version.minor == 10
        push!(dependencies, Dependency(get_addable_spec("LibUV_jll", v"2.0.1+11")))
        push!(dependencies, Dependency(get_addable_spec("LibUnwind_jll", v"1.5.0+4"); platforms=filter(!Sys.isapple, platforms)))
        push!(dependencies, Dependency(get_addable_spec("LLVMLibUnwind_jll", v"12.0.1+0"); platforms=filter(Sys.isapple, platforms)))
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_jll", v"14.0.6+0")))
    else
        error("Unsupported Julia version")
    end

    julia_compat = version ≥ v"1.6" ? "1.6" : "1.0"

    if any(should_build_platform.(triplet.(platforms)))
        build_tarballs(ARGS, name, jllversion, sources, script, platforms, products, dependencies;
                   preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat)
    end
end
