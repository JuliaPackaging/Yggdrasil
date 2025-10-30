# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize, get_addable_spec

const curl_hashes = Dict(
    v"7.81.0" => "ac8e1087711084548d788ef18b9b732c8de887457b81f616fc681d1044b32f98",
    v"7.88.1" => "cdb38b72e36bc5d33d5b8810f8018ece1baa29a8f215b4495e495ded82bbf3c7",
    v"8.2.1"  => "f98bdb06c0f52bdd19e63c4a77b5eb19b243bcbbd0f5b002b9f3cba7295a3a42",
    v"8.4.0"  => "816e41809c043ff285e8c0f06a75a1fa250211bbfb2dc0a037eeef39f1a9e427",
    v"8.5.0"  => "05fc17ff25b793a437a0906e0484b82172a9f4de02be5ed447e0cab8c3475add",
    v"8.6.0"  => "9c6db808160015f30f3c656c0dec125feb9dc00753596bf858a272b5dd8dc398",
    v"8.7.1"  => "f91249c87f68ea00cf27c44fdfa5a78423e41e71b7d408e5901a9896d905c495",
    v"8.8.0"  => "77c0e1cd35ab5b45b659645a93b46d660224d0024f1185e8a95cdb27ae3d787d",
    v"8.9.0"  => "14d931fa98a329310dca7b190d047c3d4987674b1f466481f5490e4e12067ba4",
    v"8.9.1"  => "291124a007ee5111997825940b3876b3048f7d31e73e9caa681b80fe48b2dcd5",
    v"8.11.0" => "264537d90e58d2b09dddc50944baf3c38e7089151c8986715e2aaeaaf2b8118f",
    v"8.11.1" => "a889ac9dbba3644271bd9d1302b5c22a088893719b72be3487bc3d401e5c4e80",
    v"8.12.0" => "b72ec874e403c90462dc3019c5b24cc3cdd895247402bf23893b3b59419353bc",
    v"8.12.1" => "7b40ea64947e0b440716a4d7f0b7aa56230a5341c8377d7b609649d4aea8dbcf",
    v"8.13.0" => "c261a4db579b289a7501565497658bbd52d3138fdbaccf1490fa918129ab45bc",
    v"8.14.1" => "6766ada7101d292b42b8b15681120acd68effa4a9660935853cf6d61f0d984d4",
    v"8.15.0" => "d85cfc79dc505ff800cb1d321a320183035011fa08cb301356425d86be8fc53c",
    v"8.16.0" => "a21e20476e39eca5a4fc5cfb00acf84bbc1f5d8443ec3853ad14c26b3c85b970",
)

function build_libcurl(ARGS, name::String, version::VersionNumber; with_zstd=false)
    hash = curl_hashes[version]

    if name == "CURL"
        this_is_curl_jll = true
    elseif name == "LibCURL"
        this_is_curl_jll = false
    else
        msg = "Not a valid name: $(name). Valid names are: LibCURL, CURL"
        throw(ArgumentError(msg))
    end

    # Collection of sources required to build LibCURL
    sources = [
        ArchiveSource("https://curl.se/download/curl-$(version).tar.gz", hash),
        DirectorySource("../patches"),
    ]
    if version == v"8.13"
        append!(sources, [
            ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.13.sdk.tar.xz",
                          "a3a077385205039a7c6f9e2c98ecdf2a720b2a819da715e03e0630c75782c1e4")
                ])
        unpack_macosx_sdk = raw"""
        if [[ "${target}" == x86_64-apple-darwin* ]]; then
            export MACOSX_DEPLOYMENT_TARGET=10.13
            pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
            rm -rf /opt/${target}/${target}/sys-root/System
            cp -a usr/* "/opt/${target}/${target}/sys-root/usr/"
            cp -a System "/opt/${target}/${target}/sys-root/"
            popd
        fi
        """
    else
        unpack_macosx_sdk = ""
    end
    macos_use_openssl = version >= v"8.15"

    # Disable nss only for CURL < 8.16
    without_nss = version < v"8.16.0"

    config = "THIS_IS_CURL=$(this_is_curl_jll)\n"
    config *= "MACOS_USE_OPENSSL=$(macos_use_openssl)\n"
    if with_zstd
	config *= "HAVE_ZSTD=true\n"
    end
    if without_nss
        config *= "WITHOUT_NSS=true\n"
    end

    # Bash recipe for building across all platforms
    script = config * unpack_macosx_sdk * raw"""
    cd $WORKSPACE/srcdir/curl-*

    # Address <https://github.com/curl/curl/issues/12849>
    atomic_patch -p1 $WORKSPACE/srcdir/memdup.patch

    # Holy crow we really configure the bitlets out of this thing
    FLAGS=(
        # Disable....almost everything
        --without-gnutls
        --without-libidn2 --without-librtmp
        --without-libpsl
        --disable-ares --disable-manual
        --disable-ldap --disable-ldaps --without-zsh-functions-dir
        --disable-static --without-libgsasl
        --without-brotli

        # A few things we actually enable
	--with-libssh2=${prefix} --with-zlib=${prefix} --with-nghttp2=${prefix}
        --enable-versioned-symbols
    )

    if [[ ${HAVE_ZSTD} == true ]]; then
        FLAGS+=(--with-zstd=${prefix})
    fi

    if [[ ${WITHOUT_NSS} == true ]]; then
        FLAGS+=(--without-nss)
    fi

    if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
        # Install msan runtime (for clang)
        cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
    fi

    if [[ ${target} == *mingw* ]]; then
        # We need to tell it where to find libssh2 on windows
        FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/bin")

        # We also need to tell it to link against schannel (native TLS library)
        FLAGS+=(--with-schannel)
    elif [[ ${MACOS_USE_OPENSSL} == false && ${target} == *darwin* ]]; then
        # On Darwin, we need to use SecureTransport (native TLS library) for pre-8.15 versions of CURL
        FLAGS+=(--with-secure-transport)

        # We need to explicitly request a higher `-mmacosx-version-min` here, so that it doesn't
        # complain about: `Symbol not found: ___isOSVersionAtLeast`
        if [[ "${target}" == *x86_64* ]]; then
            export CFLAGS=-mmacosx-version-min=10.11
        fi
    else
        # On all other systems, we use OpenSSL
        FLAGS+=(--with-openssl)
    fi

    if false; then
        # Use gssapi on Linux and FreeBSD
        FLAGS+=(--with-gssapi=${prefix})
        if [[ "${target}" == *-freebsd* ]]; then
            # Only for FreeBSD we need to hint that we need to link to libkrb5 and
            # libcom_err to resolve some undefined symbols.
            export LIBS="-lkrb5 -lcom_err"
        fi
    else
        FLAGS+=(--without-gssapi)
    fi

    ./configure --prefix=$prefix --host=$target --build=${MACHTYPE} "${FLAGS[@]}"
    make -j${nproc}
    if [[ "${THIS_IS_CURL}" == true ]]; then
        # Manually install only `curl`
        install -Dm 755 "src/.libs/curl${exeext}" "${bindir}/curl${exeext}"
    else
        # Install everything...
        make install
        # ...but remove `curl`
        rm "${bindir}/curl${exeext}"
    fi
    install_license COPYING
    """

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = supported_platforms()
    push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))
    # The products that we will ensure are always built
    if this_is_curl_jll
        # CURL_jll only provides the executable
        products = [
            ExecutableProduct("curl", :curl),
        ]
    else
        # LibCURL only provides the library
        products = [
            LibraryProduct("libcurl", :libcurl),
        ]
    end

    llvm_version = v"13.0.1+1"

    openssl_platforms = if macos_use_openssl
        filter(p->Sys.islinux(p) || Sys.isfreebsd(p), platforms)
    else
        filter(p->!Sys.iswindows(p), platforms)
    end

    # Dependencies that must be installed before this package can be built
    dependencies = [
        Dependency("LibSSH2_jll"),
        Dependency("Zlib_jll"),
        Dependency("nghttp2_jll"),
        Dependency("OpenSSL_jll"; compat="3.0.16", platforms=openssl_platforms),
        BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                        platforms=filter(p -> sanitize(p)=="memory", platforms)),
    ]

    if with_zstd
        push!(dependencies, Dependency("Zstd_jll"))
    end

    if this_is_curl_jll
        # Curl_jll depends on LibCURL_jll
        push!(dependencies, Dependency("LibCURL_jll"; compat="$(version)"))
    end

    # Build the tarballs, and possibly a `build.jl` as well.
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                   julia_compat="1.8", preferred_llvm_version=llvm_version)
end
