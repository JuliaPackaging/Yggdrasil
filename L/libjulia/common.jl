# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# return the platforms supported by libjulia
function libjulia_platforms(julia_version)
    platforms = supported_platforms(; experimental=julia_version ≥ v"1.7")

    # skip 32bit musl builds; they fail with this error:
    #    libunwind.so.8: undefined reference to `setcontext'
    filter!(p -> !(Sys.islinux(p) && libc(p) == "musl" && arch(p) == "i686"), platforms)

    # in Julia <= 1.3 skip PowerPC builds (see https://github.com/JuliaPackaging/Yggdrasil/pull/1795)
    if julia_version < v"1.4"
        filter!(p -> !(Sys.islinux(p) && arch(p) == "powerpc64le"), platforms)
    end

    return platforms
end

# Collection of sources required to build Julia
function build_julia(ARGS, version)
    name = "libjulia"

    checksums = Dict(
        v"1.3.1" => "3d9037d281fb41ad67b443f42d8a8e400b016068d142d6fafce1952253ae93db",
        v"1.4.2" => "76a94e06e68fb99822e0876a37c2ed3873e9061e895ab826fd8c9fc7e2f52795",
        v"1.5.3" => "be19630383047783d6f314ebe0bf5e3f95f82b0c203606ec636dced405aab1fe",
        v"1.6.0" => "c253360d29abb9a3a9e6e01493e0f7bb537d88014fd58ac561b5ba30fcb44cad",
    )

    sources = [
        ArchiveSource("https://github.com/JuliaLang/julia/releases/download/v$(version)/julia-$(version).tar.gz", checksums[version]),
        DirectorySource("./bundled"),
    ]

    # Bash recipe for building across all platforms
    script = raw"""
    apk add coreutils libuv-dev utf8proc

    cd $WORKSPACE/srcdir/julia*
    version=$(cat VERSION)

    # Apply patches
    if [ -d $WORKSPACE/srcdir/patches ]; then
    for f in $WORKSPACE/srcdir/patches/*.patch; do
        echo "Applying path ${f}"
        atomic_patch -p1 ${f}
    done
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

    if [[ "${version}" == 1.[0-5].* ]]; then
        LLVM_CXXFLAGS="-I${prefix}/include -std=c++11 -fno-exceptions -fno-rtti -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS"
    else
        LLVM_CXXFLAGS="-I${prefix}/include -std=c++14 -fno-exceptions -fno-rtti -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS"
    fi
    LLVM_LDFLAGS="-L${prefix}/lib"
    LDFLAGS="-L${prefix}/lib"
    CFLAGS="-I${prefix}/include"
    # -NDEBUG below fixes the FreeBSD build of Julia 1.4 and 1.5
    CXXFLAGS="-I${prefix}/include -DNDEBUG"
    if [[ "${target}" == *mingw* ]]; then
        LLVMLINK="-L${prefix}/bin -lLLVM"
        LLVM_LDFLAGS="-L${prefix}/bin"
        LDFLAGS="-L${prefix}/bin"
    elif [[ "${target}" == *apple* ]]; then
        LLVMLINK="-L${prefix}/lib -lLLVM"
    else
        if [[ "${version}" == 1.3.* ]]; then
            LLVMLINK="-L${prefix}/lib -lLLVM-6.0"
        elif [[ "${version}" == 1.4.* ]]; then
            LLVMLINK="-L${prefix}/lib -lLLVM-8jl"
        elif [[ "${version}" == 1.5.* ]]; then
            LLVMLINK="-L${prefix}/lib -lLLVM-9jl"
        else
            LLVMLINK="-L${prefix}/lib -lLLVM-11jl"
        fi
    fi

    # enable extglob for BB_TRIPLET_LIBGFORTRAN_CXXABI
    shopt -s extglob
    if [[ "${version}" == 1.[0-5].* ]]; then
        BB_TRIPLET_LIBGFORTRAN_CXXABI=${bb_full_target/-julia_version+([^-])}
    else
        # Strip the OS version from Darwin and FreeBSD
        BB_TRIPLET_LIBGFORTRAN_CXXABI=$(echo ${bb_full_target/-julia_version+([^-])} | sed 's/\(darwin\|freebsd\)[0-9.]*/\1/')
    fi

    cat << EOM >Make.user
    USE_SYSTEM_LLVM=1
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
    override LLVMLINK=${LLVMLINK}
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
    else
        if [[ "${version}" == 1.[0-4].* ]]; then
            # remove broken dylib placeholder to force static linking
            rm -f ${prefix}/lib/libosxunwind.dylib
        fi
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

    make BUILDING_HOST_TOOLS=1 NO_GIT=1 -j${nproc} VERBOSE=1 -C src/flisp host/flisp
    make clean -C src
    make clean -C src/support
    make clean -C src/flisp

    # We don't trust the system libm in places
    # So we include a private copy of libopenlibm
    mkdir -p usr/lib
    cp ${prefix}/*/libopenlibm.a usr/lib/

    # Mac build complains about checksum
    rm -rf /workspace/srcdir/julia-1.5.1/deps/checksums/lapack-3.9.0.tgz

    # compile libjulia but don't try to build a sysimage
    if [[ "${version}" == 1.[0-5].* ]]; then
        MAKE_TARGET=julia-ui-release
    else
        MAKE_TARGET="julia-src-release julia-cli-release"
    fi
    make USE_CROSS_FLISP=1 NO_GIT=1 LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" -j${nproc} VERBOSE=1 ${MAKE_TARGET}

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

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = libjulia_platforms(version)

    # While the "official" Julia kernel ABI itself does not involve any C++
    # symbols on the linker level, `libjulia` still exports "unofficial" symbols
    # dependent on the C++ strings ABI (coming from LLVM related code). This
    # doesn't matter if the client code is pure C, but as soon as there are
    # other (actual) C++ dependencies, we must make sure to use the matching C++
    # strings ABI. Hence we must use `expand_cxxstring_abis` below.
    platforms = expand_cxxstring_abis(platforms)

    for p in platforms
        p["julia_version"] = string(version)
    end

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libjulia", :libjulia; dont_dlopen=true),
    ]

    # Dependencies that must be installed before this package can be built/used
    dependencies = [
        Dependency("LibUnwind_jll"),
        Dependency("PCRE2_jll", compat="10.31"),
        Dependency("OpenLibm_jll"),
        Dependency("dSFMT_jll"),
        Dependency("LibUV_jll"),
        Dependency("utf8proc_jll"),
        Dependency("MbedTLS_jll"),
        Dependency("LibSSH2_jll"),
        Dependency("LibCURL_jll"),
        Dependency("Zlib_jll"),
        Dependency("p7zip_jll"),
        Dependency("MPFR_jll"),
        Dependency("GMP_jll"),
        Dependency("Objconv_jll"),
    ]
    if version < v"1.5.1"
        push!(dependencies, Dependency("LibOSXUnwind_jll", compat="0.0.5"))
    else
        push!(dependencies, Dependency("LibOSXUnwind_jll", compat="0.0.6"))
    end

    if version < v"1.6"
        push!(dependencies, Dependency("SuiteSparse_jll", compat="5.4.0"))
    else
        push!(dependencies, Dependency("SuiteSparse_jll"))
    end

    if version.major == 1 && version.minor == 3
        push!(dependencies, Dependency("OpenBLAS_jll", compat="0.3.5"))
        # there is no libLLVM_jll 6.0.1, so we use LLVM_jll instead
        push!(dependencies, Dependency("LLVM_jll", compat="6.0.1"))
        push!(dependencies, Dependency("LibGit2_jll", compat="0.28.2"))
    elseif version.major == 1 && version.minor == 4
        push!(dependencies, Dependency("OpenBLAS_jll", compat="0.3.5"))
        push!(dependencies, Dependency("libLLVM_jll", compat="8.0.1"))
        push!(dependencies, Dependency("LibGit2_jll", compat="0.28.2"))
    elseif version.major == 1 && version.minor == 5
        push!(dependencies, Dependency("OpenBLAS_jll", compat="0.3.9"))
        push!(dependencies, Dependency("libLLVM_jll", compat="9.0.1"))
        push!(dependencies, Dependency("LibGit2_jll", compat="0.28.2"))
    elseif version.major == 1 && version.minor == 6
        push!(dependencies, Dependency("OpenBLAS_jll", compat="0.3.10"))
        push!(dependencies, Dependency("libLLVM_jll", compat="11.0.0"))
        push!(dependencies, Dependency("LibGit2_jll", compat="1.0.1"))
    end

    julia_compat = version ≥ v"1.7" ? "1.6" : "1.0"

    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                   preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat)
end
