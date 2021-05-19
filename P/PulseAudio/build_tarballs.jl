# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PulseAudio"
version = v"14.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://freedesktop.org/software/pulseaudio/releases/pulseaudio-14.2.tar.gz", "902dd1928801bb5dc7b121754aa4110ce55768b5dff94a700e7bd58d3f597970")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk add gettext
apk add glib
apk add orc-compiler
apk add perl-xml-parser
apk add bash-completion
# make sure meson can find everything
sed -i -e "s~c_args = .*~c_args = ['-I${includedir}', '-L${libdir}']~" ${MESON_TARGET_TOOLCHAIN}
# I guess pulseaudio doesn't set install_rpath correctly?
find pulseaudio-* -type f | xargs sed -i "s~install_rpath : privlibdir~install_rpath : '\$ORIGIN/pulseaudio'~"
# For some reason, librt fails to get linked correctly, so add a flag
sed -i -e "s~c_link_args = .*~c_link_args = ['-lrt']~" ${MESON_TARGET_TOOLCHAIN}
cd pulseaudio-*
# Disable ffast-math; I repented
sed -i -e "s/link_args : \['-ffast-math'],//" src/daemon/meson.build
# pulseaudio seems to check for iconv_open but use libiconv_open?
sed -i -e "s/cc.has_function('iconv_open')/cc.has_function('libiconv_open')/" meson.build
# Force meson to use some libraries
if [[ "${target}" == powerpc64le-* ]]; then     sed -i -e "s~'sys/capability.h',~~"  meson.build; fi
mkdir build
cd build
# I can't figure out how to build tdb, see https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/887
meson ..  -Ddatabase="gdbm" --cross-file=${MESON_TARGET_TOOLCHAIN}
ninja
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libpulse-simple", :libpulse_simple),
    ExecutableProduct("pasuspender", :pasuspender),
    ExecutableProduct("pacmd", :pacmd),
    ExecutableProduct("pactl", :pactl),
    ExecutableProduct("pulseaudio", :pulseaudio),
    LibraryProduct("libpulse", :libpulse),
    LibraryProduct("libpulse-mainloop-glib", :libpulse_mainloop_glib),
    ExecutableProduct("pacat", :pacat)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"))
    Dependency(PackageSpec(name="BlueZ_jll", uuid="471b5b61-da80-5748-8755-67d5084d21f2"))
    Dependency(PackageSpec(name="Check_jll", uuid="491db154-c145-5abe-9c32-446728d60cce"))
    Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab"))
    Dependency(PackageSpec(name="eudev_jll", uuid="35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="Gdbm_jll", uuid="54ca2031-c8dd-5cab-9ed4-295edde1660f"))
    Dependency(PackageSpec(name="Gettext_jll", uuid="78b55507-aeef-58d4-861c-77aaff3498b1"))
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"))
    Dependency(PackageSpec(name="GStreamer_jll", uuid="aaaaf01e-2457-52c6-9fe8-886f7267d736"))
    Dependency(PackageSpec(name="libsndfile_jll", uuid="5bf562c0-5a39-5b4f-b979-f64ac885830c"))
    Dependency(PackageSpec(name="libasyncns_jll", uuid="ed080073-db63-57db-a029-74e11ae80737"))
    Dependency(PackageSpec(name="libcap_jll", uuid="eef66a8b-8d7a-5724-a8d2-7c31ae1e29ed"))
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
    Dependency(PackageSpec(name="Libtool_jll", uuid="a76c16ae-fb8f-5ff0-8826-da3b7a640f0b"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
    Dependency(PackageSpec(name="ORC_jll", uuid="fb41591b-4dee-5dae-bf56-d83afd04fbc0"))
    Dependency(PackageSpec(name="SBC_jll", uuid="da37f231-8920-5702-a09a-bdd970cb6ddc"))
    Dependency(PackageSpec(name="SoXResampler_jll", uuid="fbe68eb6-6641-54c6-99e3-f7c7c4d73a57"))
    Dependency(PackageSpec(name="SpeexDSP_jll", uuid="f2f9631b-9a4e-5b48-9975-88f638ec36a7"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
