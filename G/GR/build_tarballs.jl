using BinaryBuilder, ObjectFile

verbose = "--verbose" in ARGS

# GR already contains a bunch of tarballs for us, so we basically just download
# and rename them for our own nefarious purposes.

name = "GR"
version = v"0.41.0"
name_mapping = Dict(
    Linux(:x86_64, libc=:glibc) => ("Linux-x86_64", "516bbd70640f4f49df5968d9d85513c6f5fa923681f59c1876d54c3b055bf2c3"),
    Linux(:i686, libc=:glibc) => ("Linux-i386", "095b98bef33f3e140c7f8ed0008685b9c79925ee5c45545242e51fce837dd7a9"),
    Windows(:x86_64) => ("Windows-x86_64", "ac7437bcb067cefa17c54d6851d18d4f8220dee8bb4177e4f7c5761965c0d6cc"),
    Windows(:i686) => ("Windows-i686", "5e9ef15f0a53746fa6db965959458992314f59d33c013f693b8be3e093420e4e"),
    MacOS(:x86_64) => ("Darwin-x86_64", "1aaa4c6cfef141a3298518178e8f8dc0f73b1ac8ab5ef826c59158ab6a590500"),
)

# Downoad, unpack, extract, then repackage each of these guys
mkpath(joinpath(@__DIR__, "build"))
mkpath(joinpath(@__DIR__, "products"))
product_hashes = Dict()
for (platform, (suffix, hash)) in name_mapping
    extract_dir = joinpath(@__DIR__, "build", triplet(platform))
    rm(extract_dir; force=true, recursive=true)
    tarball_path = joinpath(@__DIR__, "build", "$(name)-v$(version)-$(triplet(platform)).tar.gz")
    BinaryBuilder.download_verify_unpack("https://github.com/sciapp/gr/releases/download/v$(version)/gr-$(version)-$(suffix).tar.gz", hash, extract_dir; tarball_path=tarball_path, ignore_existence=true, force=true, verbose=verbose)

    if platform isa MacOS
        # If we're dealing with a MacOS build, rename the top-level `.so` objects to `.dylib`
        libdir = joinpath(extract_dir, "gr", "lib")
        symlink("libGR.so", joinpath(libdir, "libGR.dylib"))
        symlink("libGR3.so", joinpath(libdir, "libGR3.dylib"))
    end

    tarball_path, hash = BinaryBuilder.package(Prefix(joinpath(extract_dir, "gr")), joinpath(@__DIR__, "products", name), version; platform=platform, verbose=verbose, force=true)
    product_hashes[triplet(platform)] = (basename(tarball_path), hash)
end

products = [
    LibraryProduct(Prefix(pwd()), "libGR", :libGR),
    LibraryProduct(Prefix(pwd()), "libGR3", :libGR3),
]

bin_path = "https://github.com/$(BinaryBuilder.get_repo_name())/releases/download/$(BinaryBuilder.get_tag_name())"
BinaryBuilder.print_buildjl(@__DIR__, name, version, products, product_hashes, bin_path)
