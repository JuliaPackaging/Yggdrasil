# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PulseAudio"
version = v"15.0.1"

short_version = "$(version.major).$(version.minor)"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://freedesktop.org/software/pulseaudio/releases/pulseaudio-$short_version.tar.gz", "a570b592351586541daf27b5e4b82555d6ac46bb6920eb847bcf5818e92f4c1e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pulseaudio-*
apk update
apk add bash-completion doxygen gettext glib orc-compiler perl-xml-parser 
sed -i -e "s~c_link_args = .*~c_link_args = ['-lrt']~" ${MESON_TARGET_TOOLCHAIN}
# make rpath work with cross compilation
atomic_patch -p2 $WORKSPACE/srcdir/patches/rpath.patch
# disable fastmath
atomic_patch -p2 $WORKSPACE/srcdir/patches/fastmath.patch
# sys/capability.h doesn't seem to be workig on PowerPC
if [[ "${target}" == powerpc64le-* ]]; then
    atomic_patch -p2 $WORKSPACE/srcdir/patches/capabilities.patch
fi
mkdir build
cd build
# optional dependencies I can't build but might be useful
# Avahi Jack LIRC tdb WebRTC 
meson ..  -Ddatabase="gdbm" --cross-file=${MESON_TARGET_TOOLCHAIN} -Dtests=false
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)
# Many dependencies are missing for armv6l
filter!(p->arch(p)!="armv6l", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("pulseaudio", :pulseaudio),
    LibraryProduct("module-native-protocol-tcp", :module_native_protocol_tcp, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-combine", :module_combine, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-native-protocol-fd", :module_native_protocol_fd, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-oss", :module_oss, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-card-restore", :module_card_restore, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-cli-protocol-unix", :module_cli_protocol_unix, "lib/pulse-$short_version/modules"),
    LibraryProduct("libpulse-mainloop-glib", :libpulse_mainloop_glib),
    LibraryProduct("module-rescue-streams", :module_rescue_streams, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-filter-heuristics", :module_filter_heuristics, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-simple-protocol-tcp", :module_simple_protocol_tcp, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-raop-sink", :module_raop_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("libpulsecommon-$short_version", :libpulsecommon, "lib/pulseaudio"),
    ExecutableProduct("pasuspender", :pasuspender),
    LibraryProduct("libprotocol-cli", :libprotocol_cli, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-mmkbd-evdev", :module_mmkbd_evdev, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-position-event-sounds", :module_position_event_sounds, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-virtual-sink", :module_virtual_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("libpulsecore-$short_version", :libpulsecore, "lib/pulseaudio"),
    LibraryProduct("module-pipe-source", :module_pipe_source, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-null-sink", :module_null_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-loopback", :module_loopback, "lib/pulse-$short_version/modules"),
    LibraryProduct("liboss-util", :liboss_util, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-bluez5-device", :module_bluez5_device, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-sine-source", :module_sine_source, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-always-sink", :module_always_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("libpulsedsp", :libpulsedsp, "lib/pulseaudio"),
    LibraryProduct("module-device-restore", :module_device_restore, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-equalizer-sink", :module_equalizer_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("libcli", :libcli, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-console-kit", :module_console_kit, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-role-cork", :module_role_cork, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-role-ducking", :module_role_ducking, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-tunnel-sink", :module_tunnel_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-udev-detect", :module_udev_detect, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-detect", :module_detect, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-tunnel-source", :module_tunnel_source, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-stream-restore", :module_stream_restore, "lib/pulse-$short_version/modules"),
    LibraryProduct("libpulse-simple", :libpulse_simple),
    LibraryProduct("module-augment-properties", :module_augment_properties, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-rtp-send", :module_rtp_send, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-remap-source", :module_remap_source, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-sine", :module_sine, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-combine-sink", :module_combine_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-intended-roles", :module_intended_roles, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-null-source", :module_null_source, "lib/pulse-$short_version/modules"),
    ExecutableProduct("pacmd", :pacmd),
    LibraryProduct("libbluez5-util", :libbluez5_util, "lib/pulse-$short_version/modules"),
    LibraryProduct("librtp", :librtp, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-bluetooth-discover", :module_bluetooth_discover, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-bluetooth-policy", :module_bluetooth_policy, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-echo-cancel", :module_echo_cancel, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-virtual-source", :module_virtual_source, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-switch-on-connect", :module_switch_on_connect, "lib/pulse-$short_version/modules"),
    LibraryProduct("libprotocol-simple", :libprotocol_simple, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-alsa-card", :module_alsa_card, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-tunnel-sink-new", :module_tunnel_sink_new, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-allow-passthrough", :module_allow_passthrough, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-http-protocol-unix", :module_http_protocol_unix, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-filter-apply", :module_filter_apply, "lib/pulse-$short_version/modules"),
    LibraryProduct("libalsa-util", :libalsa_util, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-cli-protocol-tcp", :module_cli_protocol_tcp, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-simple-protocol-unix", :module_simple_protocol_unix, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-pipe-sink", :module_pipe_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-bluez5-discover", :module_bluez5_discover, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-native-protocol-unix", :module_native_protocol_unix, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-rtp-recv", :module_rtp_recv, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-alsa-sink", :module_alsa_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-default-device-restore", :module_default_device_restore, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-virtual-surround-sink", :module_virtual_surround_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-suspend-on-idle", :module_suspend_on_idle, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-rygel-media-server", :module_rygel_media_server, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-always-source", :module_always_source, "lib/pulse-$short_version/modules"),
    LibraryProduct("libpulse", :libpulse),
    LibraryProduct("libraop", :libraop, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-dbus-protocol", :module_dbus_protocol, "lib/pulse-$short_version/modules"),
    ExecutableProduct("pacat", :pacat),
    LibraryProduct("module-match", :module_match, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-alsa-source", :module_alsa_source, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-hal-detect", :module_hal_detect, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-tunnel-source-new", :module_tunnel_source_new, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-volume-restore", :module_volume_restore, "lib/pulse-$short_version/modules"),
    LibraryProduct("libprotocol-http", :libprotocol_http, "lib/pulse-$short_version/modules"),
    ExecutableProduct("pactl", :pactl),
    LibraryProduct("module-switch-on-port-available", :module_switch_on_port_available, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-ladspa-sink", :module_ladspa_sink, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-cli", :module_cli, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-device-manager", :module_device_manager, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-http-protocol-tcp", :module_http_protocol_tcp, "lib/pulse-$short_version/modules"),
    LibraryProduct("libprotocol-native", :libprotocol_native, "lib/pulse-$short_version/modules"),
    LibraryProduct("module-remap-sink", :module_remap_sink, "lib/pulse-$short_version/modules")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"))
    Dependency(PackageSpec(name="BlueZ_jll", uuid="471b5b61-da80-5748-8755-67d5084d21f2"))
    Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab"))
    Dependency(PackageSpec(name="eudev_jll", uuid="35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="Gdbm_jll", uuid="54ca2031-c8dd-5cab-9ed4-295edde1660f"))
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"); compat="2.68.1")
    Dependency(PackageSpec(name="GStreamer_jll", uuid="aaaaf01e-2457-52c6-9fe8-886f7267d736"))
    Dependency(PackageSpec(name="libsndfile_jll", uuid="5bf562c0-5a39-5b4f-b979-f64ac885830c"))
    Dependency(PackageSpec(name="libasyncns_jll", uuid="ed080073-db63-57db-a029-74e11ae80737"))
    Dependency(PackageSpec(name="libcap_jll", uuid="eef66a8b-8d7a-5724-a8d2-7c31ae1e29ed"))
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
    Dependency(PackageSpec(name="Libtool_jll", uuid="a76c16ae-fb8f-5ff0-8826-da3b7a640f0b"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
    Dependency(PackageSpec(name="SBC_jll", uuid="da37f231-8920-5702-a09a-bdd970cb6ddc"))
    Dependency(PackageSpec(name="SoXResampler_jll", uuid="fbe68eb6-6641-54c6-99e3-f7c7c4d73a57"))
    Dependency(PackageSpec(name="SpeexDSP_jll", uuid="f2f9631b-9a4e-5b48-9975-88f638ec36a7"))
                                        
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
