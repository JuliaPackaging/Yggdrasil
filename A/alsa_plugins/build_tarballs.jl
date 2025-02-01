# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "alsa_plugins"
version = v"1.2.12"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.alsa-project.org/files/pub/plugins/alsa-plugins-$(version).tar.bz2",
                  "7bd8a83d304e8e2d86a25895d8dcb0ef0245a8df32e271959cdbdc6af39b66f2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd alsa-plugins-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())

# Many library products are not built
filter!(p -> arch(p) != "armv6l", platforms)

# Many dependencies are missing
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libasound_module_pcm_a52", :libasound_module_pcm_a52, "lib/alsa-lib"),
    LibraryProduct("libasound_module_pcm_pulse", :libasound_module_pcm_pulse, "lib/alsa-lib"),
    LibraryProduct("libasound_module_rate_lavrate", :libasound_module_rate_lavrate, "lib/alsa-lib"),
    LibraryProduct("libasound_module_pcm_speex", :libasound_module_pcm_speex, "lib/alsa-lib"),
    LibraryProduct("libasound_module_conf_pulse", :libasound_module_conf_pulse, "lib/alsa-lib"),
    LibraryProduct("libasound_module_ctl_pulse", :libasound_module_ctl_pulse, "lib/alsa-lib"),
    LibraryProduct("libasound_module_pcm_oss", :libasound_module_pcm_oss, "lib/alsa-lib"),
    LibraryProduct("libasound_module_rate_samplerate", :libasound_module_rate_samplerate, "lib/alsa-lib"),
    LibraryProduct("libasound_module_ctl_arcam_av", :libasound_module_ctl_arcam_av, "lib/alsa-lib"),
    LibraryProduct("libasound_module_pcm_usb_stream", :libasound_module_pcm_usb_stream, "lib/alsa-lib"),
    LibraryProduct("libasound_module_pcm_vdownmix", :libasound_module_pcm_vdownmix, "lib/alsa-lib"),
    LibraryProduct("libasound_module_pcm_upmix", :libasound_module_pcm_upmix, "lib/alsa-lib"),
    LibraryProduct("libasound_module_rate_speexrate", :libasound_module_rate_speexrate, "lib/alsa-lib"),
    LibraryProduct("libasound_module_ctl_oss", :libasound_module_ctl_oss, "lib/alsa-lib")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFMPEG_jll", uuid="b22a6f82-2f65-5046-a5b2-351ab43fb4e5"); compat="7.1")
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"))
    Dependency(PackageSpec(name="libsamplerate_jll", uuid="9427e74d-4e05-59c1-8ff3-7d74b6e52ac8"))
    Dependency(PackageSpec(name="PulseAudio_jll", uuid="02771fc1-bdb7-5db5-8d11-300768e00fbd"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

