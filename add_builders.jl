packages = [
    # "https://github.com/JuliaIO/FFMPEGBuilder/releases/download/v4.1.0/build_FFMPEG.v4.1.0.jl",
    # "https://github.com/JuliaIO/LibassBuilder/releases/download/v0.14.0-2/build_libass.v0.14.0.jl",
    # "https://github.com/SimonDanisch/FDKBuilder/releases/download/0.1.6/build_libfdk.v0.1.6.jl",
    # "https://github.com/SimonDanisch/FribidiBuilder/releases/download/0.14.0/build_fribidi.v0.14.0.jl",
    # "https://github.com/JuliaIO/LAMEBuilder/releases/download/v3.100.0-2/build_liblame.v3.100.0.jl",
    # "https://github.com/JuliaIO/LibVorbisBuilder/releases/download/v1.3.6-2/build_libvorbis.v1.3.6.jl",
    # "https://github.com/JuliaIO/OggBuilder/releases/download/v1.3.3-7/build_Ogg.v1.3.3.jl",
    # "https://github.com/JuliaIO/LibVPXBuilder/releases/download/v1.8.0/build_LibVPX.v1.8.0.jl",
    # "https://github.com/JuliaIO/x264Builder/releases/download/v2019.5.25-static/build_x264Builder.v2019.5.25.jl",
    # "https://github.com/JuliaIO/x265Builder/releases/download/v3.0.0-static/build_x265Builder.v3.0.0.jl",
    "https://github.com/ianshmean/ZlibBuilder/releases/download/v1.2.11/build_Zlib.v1.2.11.jl"
]
ndirs(path, n) = reduce((x, v)-> dirname(x), 1:n, init = path)
for pkg in packages
    tar_url = replace(ndirs(pkg, 4), "https://github.com" => "https://raw.githubusercontent.com") * "/master/build_tarballs.jl"
    name = titlecase(match(r"build_(.*?)\..*", basename(pkg))[1])
    folder = name[1:1]
    path = joinpath(@__DIR__, folder, name, "build_tarballs.jl")
    if !isdir(dirname(path))
        mkdir(dirname(path))
        download(tar_url, path)
    end
    build_str = read(path, String)
    deps_regex = r"https://github.com/(.*)/(.*)/releases/download/(.*)/build_(.*)\.v(.*).jl"
    build_str = replace(build_str, deps_regex => s"\4_jll")
    build_str = replace(build_str, "products(prefix) = " => "products = ")
    build_str = replace(build_str, "LibraryProduct(prefix, " => "LibraryProduct(")
    build_str = replace(build_str, "ExecutableProduct(prefix, " => "ExecutableProduct(")
    write(path, build_str)
end
