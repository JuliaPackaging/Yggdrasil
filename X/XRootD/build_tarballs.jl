# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "XRootD"
version = v"5.7.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/xrootd/xrootd/releases/download/v$(version)/xrootd-$(version).tar.gz", 
                  "c28c9dc0a2f5d0134e803981be8b1e8b1c9a6ec13b49f5fa3040889b439f4041")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir build && cd build
install_license ../xrootd-*/LICENSE
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=17 \
      ../xrootd-*/
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude= p->libc(p) == "musl" || os(p) == "freebsd" || os(p) == "windows") |> expand_cxxstring_abis

# The products that we will ensure are always built
products = [
    LibraryProduct("libXrdXml", :libXrdXml),
    LibraryProduct("libXrdUtils", :libXrdUtils),
    LibraryProduct("libXrdSsiShMap", :libXrdSsiShMap),
    LibraryProduct("libXrdSsiLib", :libXrdSsiLib),
    LibraryProduct("libXrdServer", :libXrdServer),
    LibraryProduct("libXrdPosixPreload", :libXrdPosixPreload),
    LibraryProduct("libXrdPosix", :libXrdPosix),
    LibraryProduct("libXrdHttpUtils", :libXrdHttpUtils),
    LibraryProduct("libXrdFfs", :libXrdFfs),
    LibraryProduct("libXrdCryptoLite", :libXrdCryptoLite),
    LibraryProduct("libXrdCrypto", :libXrdCrypto),
    LibraryProduct("libXrdCl", :libXrdCl),
    LibraryProduct("libXrdAppUtils", :libXrdAppUtils),
    FileProduct(["lib/libXrdSecsss-5.so","lib64/libXrdSecsss-5.so"], :libXrdSecsss),
    FileProduct(["lib/libXrdSecgsi-5.so","lib64/libXrdSecgsi-5.so"], :libXrdSecgsi),
    FileProduct(["lib/libXrdXrootd-5.so","lib64/libXrdXrootd-5.so"], :libXrdXrootd),
    FileProduct(["lib/libXrdThrottle-5.so","lib64/libXrdThrottle-5.so"], :libXrdThrottle),
    FileProduct(["lib/libXrdSsiLog-5.so","lib64/libXrdSsiLog-5.so"], :libXrdSsiLog),
    FileProduct(["lib/libXrdSsi-5.so","lib64/libXrdSsi-5.so"], :libXrdSsi),
    FileProduct(["lib/libXrdSecunix-5.so","lib64/libXrdSecunix-5.so"], :libXrdSecunix),
    FileProduct(["lib/libXrdSecpwd-5.so","lib64/libXrdSecpwd-5.so"], :libXrdSecpwd),
    FileProduct(["lib/libXrdSecProt-5.so","lib64/libXrdSecProt-5.so"], :libXrdSecProt),
    FileProduct(["lib/libXrdSecgsiGMAPDN-5.so","lib64/libXrdSecgsiGMAPDN-5.so"], :libXrdSecgsiGMAPDN),
    FileProduct(["lib/libXrdSecgsiAUTHZVO-5.so","lib64/libXrdSecgsiAUTHZVO-5.so"], :libXrdSecgsiAUTHZVO),
    FileProduct(["lib/libXrdSec-5.so","lib64/libXrdSec-5.so"], :libXrdSec),
    FileProduct(["lib/libXrdPss-5.so","lib64/libXrdPss-5.so"], :libXrdPss),
    FileProduct(["lib/libXrdPfc-5.so","lib64/libXrdPfc-5.so"], :libXrdPfc),
    FileProduct(["lib/libXrdOssSIgpfsT-5.so","lib64/libXrdOssSIgpfsT-5.so"], :libXrdOssSIgpfsT),
    FileProduct(["lib/libXrdOssCsi-5.so","lib64/libXrdOssCsi-5.so"], :libXrdOssCsi),
    FileProduct(["lib/libXrdOfsPrepGPI-5.so","lib64/libXrdOfsPrepGPI-5.so"], :libXrdOfsPrepGPI),
    FileProduct(["lib/libXrdN2No2p-5.so","lib64/libXrdN2No2p-5.so"], :libXrdN2No2p),
    FileProduct(["lib/libXrdHttp-5.so","lib64/libXrdHttp-5.so"], :libXrdHttp),
    FileProduct(["lib/libXrdCryptossl-5.so","lib64/libXrdCryptossl-5.so"], :libXrdCryptossl),
    FileProduct(["lib/libXrdCmsRedirectLocal-5.so","lib64/libXrdCmsRedirectLocal-5.so"], :libXrdCmsRedirectLocal),
    FileProduct(["lib/libXrdClProxyPlugin-5.so","lib64/libXrdClProxyPlugin-5.so"], :libXrdClProxyPlugin),
    FileProduct(["lib/libXrdCksCalczcrc32-5.so","lib64/libXrdCksCalczcrc32-5.so"], :libXrdCksCalczcrc32),
    FileProduct(["lib/libXrdBwm-5.so","lib64/libXrdBwm-5.so"], :libXrdBwm),
    FileProduct(["lib/libXrdBlacklistDecision-5.so","lib64/libXrdBlacklistDecision-5.so"], :libXrdBlacklistDecision),
    ExecutableProduct("frm_xfragent", :frm_xfragent),
    ExecutableProduct("xrdmapc", :xrdmapc),
    ExecutableProduct("xrdsssadmin", :xrdsssadmin),
    ExecutableProduct("xrdpwdadmin", :xrdpwdadmin),
    ExecutableProduct("frm_xfrd", :frm_xfrd),
    ExecutableProduct("xrdacctest", :xrdacctest),
    ExecutableProduct("frm_purged", :frm_purged),
    ExecutableProduct("xrdfs", :xrdfs),
    ExecutableProduct("xrootd", :xrootd),
    ExecutableProduct("xrdcrc32c", :xrdcrc32c),
    ExecutableProduct("wait41", :wait41),
    ExecutableProduct("xrdpfc_print", :xrdpfc_print),
    ExecutableProduct("cconfig", :cconfig),
    ExecutableProduct("xrdcp", :xrdcp),
    ExecutableProduct("xrdgsiproxy", :xrdgsiproxy),
    ExecutableProduct("frm_admin", :frm_admin),
    ExecutableProduct("mpxstats", :mpxstats),
    ExecutableProduct("xrdgsitest", :xrdgsitest),
    ExecutableProduct("cmsd", :cmsd),
    ExecutableProduct("xrdadler32", :xrdadler32),
    ExecutableProduct("xrdpinls", :xrdpinls)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libuuid_jll", uuid="38a345b3-de98-5d2b-a5d3-14cd9215e700"))
    Dependency(PackageSpec(name="libxcrypt_legacy_jll", uuid="5ef642bb-a58b-5208-ae37-583168b2c491"))
    Dependency(PackageSpec(name="JSON_C_jll", uuid="9cdfc4e7-e793-5089-b6f7-569a57a60f0a"))
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.15")
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6")
