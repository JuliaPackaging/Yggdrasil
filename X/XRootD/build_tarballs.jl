# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "XRootD"
version = v"5.5.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/xrootd/xrootd/releases/download/v$(version)/xrootd-$(version).tar.gz", "41a8557ea2d118b1950282b17abea9230b252aa5ee1a5959173e2534b7d611d3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir build && cd build
install_license ../xrootd-*/LICENSE
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DENABLE_PERL=FALSE ../xrootd-*/
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=p->libc(p) != "glibc"))


# The products that we will ensure are always built
products = [
    LibraryProduct("libXrdPss-5", :libXrdPss),
    LibraryProduct("libXrdClProxyPlugin-5", :libXrdClProxyPlugin),
    LibraryProduct("libXrdCl", :libXrdCl),
    LibraryProduct("libXrdXrootd-5", :libXrdXrootd),
    LibraryProduct("libXrdSecunix-5", :libXrdSecunix),
    LibraryProduct("libXrdHttpUtils", :libXrdHttpUtils),
    LibraryProduct("libXrdSecpwd-5", :libXrdSecpwd),
    LibraryProduct("libXrdPosix", :libXrdPosix),
    LibraryProduct("libXrdHttp-5", :libXrdHttp),
    LibraryProduct("libXrdCksCalczcrc32-5", :libXrdCksCalczcrc32),
    LibraryProduct("libXrdServer", :libXrdServer),
    LibraryProduct("libXrdPfc-5", :libXrdPfc),
    LibraryProduct("libXrdSsiLib", :libXrdSsiLib),
    LibraryProduct("libXrdOfsPrepGPI-5", :libXrdOfsPrepGPI),
    LibraryProduct("libXrdSec-5", :libXrdSec),
    LibraryProduct("libXrdPosixPreload", :libXrdPosixPreload),
    LibraryProduct("libXrdSecgsiGMAPDN-5", :libXrdSecgsiGMAPDN),
    LibraryProduct("libXrdAppUtils", :libXrdAppUtils),
    LibraryProduct("libXrdBlacklistDecision-5", :libXrdBlacklistDecision),
    LibraryProduct("libXrdOssCsi-5", :libXrdOssCsi),
    LibraryProduct("libXrdCmsRedirectLocal-5", :libXrdCmsRedirectLocal),
    LibraryProduct("libXrdBwm-5", :libXrdBwm),
    LibraryProduct("libXrdSsi-5", :libXrdSsi),
    LibraryProduct("libXrdXml", :libXrdXml),
    LibraryProduct("libXrdOssSIgpfsT-5", :libXrdOssSIgpfsT),
    LibraryProduct("libXrdSsiLog-5", :libXrdSsiLog),
    LibraryProduct("libXrdUtils", :libXrdUtils),
    LibraryProduct("libXrdSecgsiAUTHZVO-5", :libXrdSecgsiAUTHZVO),
    LibraryProduct("libXrdCrypto", :libXrdCrypto),
    LibraryProduct("libXrdCryptossl-5", :libXrdCryptossl),
    LibraryProduct("libXrdSecProt-5", :libXrdSecProt),
    LibraryProduct("libXrdSecgsi-5", :libXrfSecgsi),
    LibraryProduct("libXrdSecsss-5", :libXrfSecsss),
    LibraryProduct("libXrdFfs", :libXrdFfs),
    LibraryProduct("libXrdCryptoLite", :libXrdCryptoLite),
    LibraryProduct("libXrdSsiShMap", :libXrdSsiShMap),
    LibraryProduct("libXrdN2No2p-5", :libXrdN2No2p),
    LibraryProduct("libXrdThrottle-5", :libXrdThrottle),
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
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="1.1.10")
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5", julia_compat="1.6")
