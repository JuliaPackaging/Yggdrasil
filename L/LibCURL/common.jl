# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

function build_libcurl(ARGS, name::String)
    version = v"7.81.0"
    hash = "ac8e1087711084548d788ef18b9b732c8de887457b81f616fc681d1044b32f98"

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
    ]

    # Bash recipe for building across all platforms
    script = raw"""
    cd $WORKSPACE/srcdir/curl-*

    # Holy crow we really configure the bitlets out of this thing
    FLAGS=(
        # Disable....almost everything
        --without-ssl --without-gnutls --without-gssapi
        --without-libidn --without-libidn2 --without-librtmp
        --without-nss --without-polarssl
        --without-spnego --without-libpsl --disable-ares --disable-manual
        --disable-ldap --disable-ldaps --without-zsh-functions-dir
        --disable-static --without-libgsasl

        # A few things we actually enable
        --with-libssh2=${prefix} --with-zlib=${prefix} --with-nghttp2=${prefix}
        --enable-versioned-symbols
    )


    if [[ ${target} == *mingw* ]]; then
        # We need to tell it where to find libssh2 on windows
        FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/bin")

        # We also need to tell it to link against schannel (native TLS library)
        FLAGS+=(--with-schannel)
    elif [[ ${target} == *darwin* ]]; then
        # On Darwin, we need to use SecureTransport (native TLS library)
        FLAGS+=(--with-secure-transport)

        # We need to explicitly request a higher `-mmacosx-version-min` here, so that it doesn't
        # complain about: `Symbol not found: ___isOSVersionAtLeast`
        if [[ "${target}" == *x86_64* ]]; then
            export CFLAGS=-mmacosx-version-min=10.11
        fi
    else
        # On all other systems, we use MbedTLS
        FLAGS+=(--with-mbedtls=${prefix})
    fi

    ./configure --prefix=$prefix --host=$target --build=${MACHTYPE} "${FLAGS[@]}"
    make -j${nproc}
    make install
    install_license COPYING
    """

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = supported_platforms()

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

    # Dependencies that must be installed before this package can be built
    dependencies = [
        Dependency("LibSSH2_jll"),
        Dependency("Zlib_jll"),
        Dependency("nghttp2_jll"),
        # Note that while we unconditionally list MbedTLS as a dependency,
        # we default to schannel/SecureTransport on Windows/MacOS.
        Dependency("MbedTLS_jll"; compat="~2.28.0", platforms=filter(p->Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
    ]

    if this_is_curl_jll
        # Curl_jll depends on LibCURL_jll
        push!(dependencies, Dependency("LibCURL_jll"; compat="$(version)"))
    end

    # Build the tarballs, and possibly a `build.jl` as well.
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8")
end
