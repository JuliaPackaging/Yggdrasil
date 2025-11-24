# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include(joinpath("..", "common.jl"))

name = "FFMPEG"

# The products that we will ensure are always built
products = [
    ExecutableProduct("ffmpeg", :ffmpeg),
    ExecutableProduct("ffprobe", :ffprobe),
    LibraryProduct(["libavcodec", "avcodec"], :libavcodec),
    LibraryProduct(["libavdevice", "avdevice"], :libavdevice),
    LibraryProduct(["libavfilter", "avfilter"], :libavfilter),
    LibraryProduct(["libavformat", "avformat"], :libavformat),
    LibraryProduct(["libavutil", "avutil"], :libavutil),
    LibraryProduct(["libswresample", "swresample"], :libswresample),
    LibraryProduct(["libswscale", "swscale"], :libswscale),
]

# Dependencies that must be installed before this package can be built.
# TODO: Theora once it's available
dependencies = [
    HostBuildDependency("NASM_jll"),
    BuildDependency("nv_codec_headers_jll"),
    Dependency("libass_jll"; compat="0.17.4"),
    Dependency("libfdk_aac_jll"; compat="2.0.4"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("LAME_jll"),
    Dependency("libvorbis_jll"),
    Dependency("libaom_jll"),
    Dependency("Ogg_jll"),
    BuildDependency("LibVPX_jll"), # We use the static archive
    Dependency("x264_jll"; compat="10164.0.1"),
    Dependency("x265_jll"; compat="~4.1"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Zlib_jll"),
    Dependency("OpenSSL_jll"; compat="3.5.0"),
    Dependency("Opus_jll"),
    Dependency("PCRE2_jll"; compat="10.42.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script(; ffplay=false), platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=preferred_gcc_version, clang_use_lld=false)

# Build trigger: 2
