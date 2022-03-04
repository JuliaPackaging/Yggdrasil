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
    LibraryProduct(["libavresample", "avresample"], :libavresample),
    LibraryProduct(["libavutil", "avutil"], :libavutil),
    LibraryProduct(["libpostproc", "postproc"], :libpostproc),
    LibraryProduct(["libswresample", "swresample"], :libswresample),
    LibraryProduct(["libswscale", "swscale"], :libswscale),
]

# Dependencies that must be installed before this package can be built.
# TODO: Theora once it's available
dependencies = [
    BuildDependency("nv_codec_headers_jll"),
    Dependency("libass_jll"; compat="0.15.1"),
    Dependency("libfdk_aac_jll"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"),
    Dependency("LAME_jll"),
    Dependency("libvorbis_jll"),
    Dependency("Ogg_jll"),
    BuildDependency("LibVPX_jll"), # We use the static archive
    Dependency("x264_jll"; compat="~2021.05.05"),
    Dependency("x265_jll"; compat="~3.5"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Zlib_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("Opus_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script(; ffplay=false), platforms, products, dependencies; preferred_gcc_version=preferred_gcc_version, julia_compat="1.6")
