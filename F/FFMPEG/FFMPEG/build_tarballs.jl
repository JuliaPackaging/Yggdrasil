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
    LibraryProduct(["libpostproc", "postproc"], :libpostproc),
    LibraryProduct(["libswresample", "swresample"], :libswresample),
    LibraryProduct(["libswscale", "swscale"], :libswscale),
]

# Dependencies that must be installed before this package can be built.
# TODO: Theora once it's available
dependencies = [
    HostBuildDependency("YASM_jll"),
    BuildDependency("nv_codec_headers_jll"),
    Dependency("libass_jll"; compat="0.15.1"),
    Dependency("libfdk_aac_jll"; compat="2.0.3"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("LAME_jll"),
    Dependency("libvorbis_jll"),
    Dependency("libaom_jll"),
    Dependency("Ogg_jll"),
    BuildDependency("LibVPX_jll"), # We use the static archive
    Dependency("x264_jll"; compat="10164.0.0"),
    Dependency("x265_jll"; compat="~3.6"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Zlib_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.9"),
    Dependency("Opus_jll"),
    Dependency("PCRE2_jll"; compat="10.35"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script(; ffplay=false), platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=preferred_gcc_version, clang_use_lld=false)
