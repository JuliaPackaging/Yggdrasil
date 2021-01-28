
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoXResampler"
version = v"0.1.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://freedesktop.org/software/pulseaudio/releases/pulseaudio-14.2.tar.gz"
    )
]

# Bash recipe for building across all platforms
script = raw"""
apk add alsa-lib
apk add alsa-lib-dev
apk add alsa-utils
apk add check
apk add check-dev
apk add dbus
apk add dbus-dev
apk add fftw 
apk add fftw-dev 
apk add gdbm
apk add gdbm-dev
apk add gettext
apk add gettext-dev
apk add glib
apk add glib-dev
apk add gnu-libiconv
apk add gnu-libiconv-dev
apk add libasyncns 
apk add libasyncns-dev
apk add libcap 
apk add libcap-dev 
apk add libgomp
apk add libintl
apk add libtool
apk add openssl 
apk add openssl-dev 
apk add orc
apk add orc-dev
apk add orc-compiler
apk add perl-xml-parser
apk add sbc 
apk add sbc-dev 
apk add soxr 
apk add soxr-dev
apk add speex 
apk add speexdsp-dev
apk add udev
hash -r
# For some reason, librt fails to get linked correctly, so add a flag
sed -i -e 's/c_link_args = .*/c_link_args = ["-lrt",]/' ${MESON_TARGET_TOOLCHAIN}
cd pulseaudio-*
# This version of iconv seems to be incomplete, so prevent pulse audio from detecting it?
sed -i -e "s/cc.has_function('iconv_open')/false/" meson.build
# Disable ffast-math; I repented
sed -i -e "s/link_args : \['-ffast-math'],//" src/daemon/meson.build
mkdir build
cd build
# I can't figure out how to build tdb, use gdbm instead
# BlueZ requires systemd, which I'm also stuck on
meson ..  -Ddatabase="gdbm" -Dbluez5="false" --cross-file=${MESON_TARGET_TOOLCHAIN}
ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ...
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll")),
    Dependency(PackageSpec(name="Check_jll")),
    Dependency(PackageSpec(name="Dbus_jll")),
    Dependency(PackageSpec(name="FFTW_jll")),
    Dependency(PackageSpec(name="Gdbm_jll")),
    Dependency(PackageSpec(name="Gettext_jll")),
    Dependency(PackageSpec(name="Glib_jll")),
    Dependency(PackageSpec(name="ICU_jll")),
    Dependency(PackageSpec(name="libasyncns_jll")),
    Dependency(PackageSpec(name="libcap_jll")),
    Dependency(PackageSpec(name="Libiconv_jll")),
    Dependency(PackageSpec(name="Libtool_jll")),
    Dependency(PackageSpec(name="OpenMPI_jll")),
    Dependency(PackageSpec(name="OpenSSL_jll")),
    Dependency(PackageSpec(name="ORC_jll")),
    Dependency(PackageSpec(name="SBC_jll")),
    Dependency(PackageSpec(name="SoXResampler_jll")),
    Dependency(PackageSpec(name="SpeexDSP_jll"))
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
