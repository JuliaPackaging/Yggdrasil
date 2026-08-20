using BinaryBuilder, Pkg
using BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "microarchitectures.jl"))

name = "PipeWireAO"
version = v"1.7.0"

sources = [
    GitSource(
        "https://github.com/DarrylGamroth/PipeWireAO.git",
        "d48418553fd372fc69cb7042a8370c099750a0ee",
    ),
    DirectorySource("./bundled"),
]

# Package the AO client/core infrastructure without external desktop audio
# bridges or a session manager. Built-in SPA processing remains available to
# the core modules. Runtime module loading happens during setup, before an AO
# worker enters its allocation-free execution path.
script = raw"""
cd ${WORKSPACE}/srcdir/PipeWireAO
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/binarybuilder-compat.patch

meson setup builddir \
    --buildtype=release \
    --cross-file=${MESON_TARGET_TOOLCHAIN} \
    --prefix=${prefix} \
    -Dauto_features=disabled \
    -Dexamples=disabled \
    -Dtests=disabled \
    -Dinstalled_tests=disabled \
    -Dpipewire-jack=disabled \
    -Dpipewire-v4l2=disabled \
    -Dpipewire-alsa=disabled \
    -Dalsa=disabled \
    -Dbluez5=disabled \
    -Djack=disabled \
    -Dv4l2=disabled \
    -Dlibcamera=disabled \
    -Daudiomixer=disabled \
    -Daudioconvert=enabled \
    -Dcontrol=disabled \
    -Daudiotestsrc=disabled \
    -Dvideoconvert=disabled \
    -Dvideotestsrc=disabled \
    -Ddbus=disabled \
    -Dflatpak=disabled \
    -Dsession-managers=[] \
    -Dlegacy-rtkit=false \
    -Drlimits-install=false

meson compile -C builddir -j${nproc}
meson install -C builddir
install_license LICENSE
"""

# PipeWireAO is Linux-native. Publish only the AO deployment architectures:
# an aarch64 baseline plus baseline, AVX2, and AVX-512 x86-64 artifacts.
platforms = filter(
    p -> Sys.islinux(p) && libc(p) == "glibc" && arch(p) in ("aarch64", "x86_64"),
    supported_platforms(),
)
platforms = expand_microarchitectures(
    platforms,
    ["x86_64", "avx2", "avx512"];
    filter=p -> arch(p) == "x86_64",
)

augment_platform_block = """
    $(MicroArchitectures.augment)
    function augment_platform!(platform::Platform)
        @static if Sys.ARCH === :x86_64
            augment_microarchitecture!(platform)
        else
            platform
        end
    end
    """

products = [
    LibraryProduct("libpipewire-ao-0.3", :libpipewire_ao),
    LibraryProduct("libspa-ao", :libspa_ao, "lib/spa-ao-0.2"),
    LibraryProduct(
        "libspa-support",
        :libspa_support,
        "lib/spa-ao-0.2/support";
        dont_dlopen=true,
    ),
]

dependencies = []

init_block = raw"""
ENV["PIPEWIREAO_SPA_PLUGIN_DIR"] = get(ENV, "PIPEWIREAO_SPA_PLUGIN_DIR", joinpath(artifact_dir, "lib", "spa-ao-0.2"))
ENV["PIPEWIREAO_MODULE_DIR"] = get(ENV, "PIPEWIREAO_MODULE_DIR", joinpath(artifact_dir, "lib", "pipewire-ao-0.3"))
ENV["PIPEWIREAO_CONFIG_DIR"] = get(ENV, "PIPEWIREAO_CONFIG_DIR", joinpath(artifact_dir, "share", "pipewire-ao"))
"""

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    init_block,
    augment_platform_block,
    julia_compat="1.10",
    preferred_gcc_version=v"11",
)
