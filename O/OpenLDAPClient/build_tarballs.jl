# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenLDAPClient"
version = v"2.4.50"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.4.50.tgz", "5cb57d958bf5c55a678c6a0f06821e0e5504d5a92e6a33240841fbca1db586b8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk add groff
cd openldap*

#needed to build shared libraries
if [[ "${target}" == *-freebsd* || "${target}" == powerpc* || "${target}" == *-mingw* ]]; then
	libtoolize --force --copy
	AUTOMAKE=/bin/true autoreconf -fi
fi

#need a posix regex
if [[ "${target}" == *-mingw* ]]; then
	cp ${prefix}/include/pcreposix.h ${prefix}/include/regex.h 
	export LDFLAGS="-lpcreposix-0 -L${prefix}/bin"
fi

#The mac build tries to pick up libraries from system root
rm -f /opt/${target}/${target}/sys-root/usr/lib/libcrypto.*
rm -f /opt/${target}/${target}/sys-root/usr/lib/libssl.*
rm -f /opt/${target}/${target}/sys-root/usr/lib/libsasl2.*
rm -f /lib/libcrypto.so*
rm -f /usr/lib/libcrypto.so*
rm -f /lib/libssl.so*
rm -f /usr/lib/libssl.so*

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-slapd --without-yielding_select --disable-static --enable-shared --enable-modules=yes --enable-hdb=no --enable-bdb=no
sed -in-place 's/#define NEED_MEMCMP_REPLACEMENT 1/\/\* #undef NEED_MEMCMP_REPLACEMENT \*\//' include/portable.h

make depend
make -j${nproc} 
make install

if [[ "${target}" == *-mingw* ]]; then 
    # Cover up the traces of the hack 
    rm ${prefix}/include/regex.h 
fi 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
products = [
    ExecutableProduct("ldapdelete", :ldapdelete),
    LibraryProduct("libldap", :libldap),
    ExecutableProduct("ldapsearch", :ldapsearch),
    ExecutableProduct("ldapwhoami", :ldapwhoami),
    LibraryProduct("liblber", :liblber),
    ExecutableProduct("ldapurl", :ldapurl),
    ExecutableProduct("ldappasswd", :ldappasswd),
    ExecutableProduct("ldapmodify", :ldapmodify),
    ExecutableProduct("ldapexop", :ldapexop),
    ExecutableProduct("ldapmodrdn", :ldapmodrdn),
    LibraryProduct("libldap_r", :libldap_r),
    ExecutableProduct("ldapcompare", :ldapcompare)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
    Dependency(PackageSpec(name="PCRE_jll",  uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
