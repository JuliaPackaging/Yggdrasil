# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.Types

# Collection of sources required to build GMP
function build_julia(version)
    name = "libjulia"

    checksums = Dict(
        v"1.3.1" => "053908ec2706eb76cfdc998c077de123ecb1c60c945b4b5057aa3be19147b723",
        v"1.4.2" => "948c70801d5cce81eeb7f764b51b4bfbb2dc0b1b9effc2cb9fc8f8cf6c90a334",
        v"1.5.1" => "1d0debfccfc7cd07047aa862dd2b1a96f7438932da1f5feff6c1033a63f9b1d4",
    )
    sources = [
        ArchiveSource("https://github.com/JuliaLang/julia/releases/download/v$(version)/julia-$(version)-full.tar.gz", checksums[version]),
        DirectorySource("./bundled"),
    ]

    # Bash recipe for building across all platforms
    script = raw"""
    apk update
    apk add coreutils libuv-dev utf8proc-dev

    cd $WORKSPACE/srcdir/julia*

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

    if [[ "${target}" == *mingw* ]]; then
        LLVMLINK="-L${prefix}/bin -lLLVM"
        LLVM_CXXFLAGS="-I${prefix}/include -std=c++14 -fno-exceptions -fno-rtti -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS"
        LLVM_LDFLAGS="-L${prefix}/bin"
        LDFLAGS="-L${prefix}/bin"
    else
        LLVMLINK="-L${prefix}/lib -lLLVM-9jl"
        LLVM_CXXFLAGS="-I${prefix}/include -std=c++14 -fno-exceptions -fno-rtti -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS"
        LLVM_LDFLAGS="-L${prefix}/lib"
        LDFLAGS=""
    fi

    cat << EOM >Make.user
    #USE_SYSTEM_LLVM=1
    USE_SYSTEM_LIBUNWIND=1
    USE_SYSTEM_PCRE=1
    USE_SYSTEM_OPENLIBM=1
    USE_SYSTEM_DSFMT=1
    #USE_SYSTEM_BLAS=1
    #LIBBLASNAME=libopenblas
    #USE_SYSTEM_LAPACK=1
    #LIBLAPACKNAME=libopenblas
    #USE_SYSTEM_GMP=1
    #USE_SYSTEM_MPFR=1
    #USE_SYSTEM_SUITESPARSE=1
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
    override LLVM_CONFIG_HOST=

    # we only run flisp and we built that for Linux
    override spawn = \$(1)
    override cygpath_w = \$(1)

    # julia expects libuv-julia.a
    override LIBUV=${prefix}/lib/libuv.a

    prefix=${prefix}
    LOCALBASE=${prefix}

    override USE_BINARYBUILDER=1
    override BB_TRIPLET_LIBGFORTRAN_CXXABI=${bb_full_target}
    EOM

    # Add file to one of the `STD_LIB_PATH`
    if [[ "${target}" == *mingw* ]]; then
        cp /opt/*-w64-mingw32/*-w64-mingw32/sys-root/bin/libwinpthread-1.dll /opt/*-w64-mingw32/*-mingw32/sys-root/lib/
    fi

    make BUILDING_HOST_TOOLS=1 NO_GIT=1 -j${nproc} -C src/flisp host/flisp
    make clean -C src
    make clean -C src/support
    make clean -C src/flisp

    # We don't trust the system libm in places
    # So we include a private copy of libopenlibm
    mkdir -p usr/lib
    cp ${prefix}/lib/libopenlibm.a usr/lib/

    # compile libjulia but don't try to build a sysimage
    make USE_CROSS_FLISP=1 NO_GIT=1 LDFLAGS=${LDFLAGS} -j${nproc} julia-ui-release

    # 'manually' install libraries and headers
    mkdir -p ${libdir}
    mkdir -p ${includedir}/julia
    if [[ "${target}" == *mingw* ]]; then
        cp usr/bin/libjulia* ${bindir}/
    else
        cp usr/lib/libjulia* ${libdir}/
    fi
    
    cp -R -L usr/include/julia/* ${includedir}/julia
    install_license LICENSE.md
    """

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    #
    # While the "official" Julia kernel ABI itself does not involve any C++
    # symbols on the linker level, `libjulia` still exports "unofficial" symbols
    # dependent on the C++ strings ABI (coming from LLVM related code). This
    # doesn't matter if the client code is pure C, but as soon as there are
    # other (actual) C++ dependencies, we must make sure to use the matching C++
    # strings ABI. Hence we must use `expand_cxxstring_abis` below.
    platforms = supported_platforms()
    filter!(!=(Linux(:i686, libc=:musl)), platforms)
    platforms = expand_cxxstring_abis(platforms)

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libjulia", :libjulia; dont_dlopen=true),
    ]

    # Dependencies that must be installed before this package can be built/used
    dependencies = [
        Dependency("LibUnwind_jll"),
        Dependency("LibOSXUnwind_jll"),
        Dependency(PackageSpec(name="PCRE2_jll", version=v"10.31")),
        Dependency("OpenLibm_jll"),
        Dependency("dSFMT_jll"),
#        Dependency(PackageSpec(name="SuiteSparse_jll", version=v"5.4.0")),
        Dependency("LibUV_jll"),
        Dependency("utf8proc_jll"),
        Dependency("MbedTLS_jll"),
        Dependency("LibSSH2_jll"),
        Dependency("LibCURL_jll"),
#        Dependency("Patchelf_jll"),
        Dependency("Zlib_jll"),
        Dependency("p7zip_jll"),
        Dependency("LibGit2_jll"),
    ]
    if version.major == 1 && version.minor == 4
#        push!(dependencies, Dependency(PackageSpec(name="OpenBLAS_jll", version=v"0.3.5")))
        push!(dependencies, Dependency(PackageSpec(name="libLLVM_jll", version=v"8.0.1")))
#        #push!(dependencies, Dependency(PackageSpec(name="MPFR_jll", version=v"4.0.2")))
#        #push!(dependencies, Dependency(PackageSpec(name="GMP_jll", version=v"6.1.2")))
#        #push!(dependencies, Dependency(PackageSpec(name="LibGit2_jll", version=v"0.28.2")))
    elseif version.major == 1 && version.minor == 5
#        push!(dependencies, Dependency(PackageSpec(name="OpenBLAS_jll", version=v"0.3.9")))
        push!(dependencies, Dependency(PackageSpec(name="libLLVM_jll", version=v"9.0.1")))
#        #push!(dependencies, Dependency(PackageSpec(name="MPFR_jll", version=v"4.1.0")))
#        #push!(dependencies, Dependency(PackageSpec(name="GMP_jll", version=v"6.1.2")))
#        #push!(dependencies, Dependency(PackageSpec(name="LibGit2_jll", version=v"0.28.2")))
    elseif version.major == 1 && version.minor == 6
#        push!(dependencies, Dependency(PackageSpec(name="OpenBLAS_jll", version=v"0.3.10")))
        push!(dependencies, Dependency(PackageSpec(name="libLLVM_jll", version=v"9.0.1")))
#        #push!(dependencies, Dependency(PackageSpec(name="MPFR_jll", version=v"4.1.0")))
#        #push!(dependencies, Dependency(PackageSpec(name="GMP_jll", version=v"6.2.0")))
#        #push!(dependencies, Dependency(PackageSpec(name="LibGit2_jll", version=v"1.0.1")))
    end

    # Build the tarballs, and possibly a `build.jl` as well.
    global ARGS
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", lock_microarchitecture=false)
end
