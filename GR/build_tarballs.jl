using BinaryBuilder, ObjectFile

verbose = "--verbose" in ARGS

# GR already contains a bunch of tarballs for us, so we basically just download
# and rename them for our own nefarious purposes.

name = "GR"
version = v"0.39.0"
name_mapping = Dict(
    Linux(:x86_64, libc=:glibc) => ("Linux-x86_64", "cb5e1eb4bc94ccf7ddef268679cd4d0853a1e8ecb2f21c2a9025a14f32bfbd79"),
    Linux(:i686, libc=:glibc) => ("Linux-i386", "fb3fbdb19061224b14fb59a864ddfb5b34744dc77c0d7a6574b3de677c680641"),
    Windows(:x86_64) => ("Windows-x86_64", "da0ec3e26855de4c05043bd1c49445ddafeba837113580140f25613e25150d9f"),
    Windows(:i686) => ("Windows-i686", "9e927fcedb784eb60ca3ed682bb056c59b52526d7cfa7cfd1d4e1978d415acc7"),
    MacOS(:x86_64) => ("Darwin-x86_64", "bf871c66fa3445b49771af803066d9f5cab175b3aa837714375c4b8ef2c067b8"),
)

# Downoad, unpack, extract, then repackage each of these guys
mkpath(joinpath(@__DIR__, "build"))
mkpath(joinpath(@__DIR__, "products"))
product_hashes = Dict()
for (platform, (suffix, hash)) in name_mapping
    extract_dir = joinpath(@__DIR__, "build", triplet(platform))
    tarball_path = joinpath(@__DIR__, "build", "$(name)-v$(version)-$(triplet(platform)).tar.gz")
    BinaryBuilder.download_verify_unpack("https://github.com/sciapp/gr/releases/download/v$(version)/gr-$(version)-$(suffix).tar.gz", hash, extract_dir; tarball_path=tarball_path, ignore_existence=true, force=true, verbose=verbose)

    if platform isa MacOS
        # If we're dealing with a MacOS build, rename everything from `.so`, which is just ridiculous.
        libdir = joinpath(extract_dir, "gr", "lib")
        ur = BinaryBuilder.preferred_runner()(libdir; cwd="/workspace/", platform=platform)
        install_name_tool = "/opt/x86_64-apple-darwin14/bin/install_name_tool"
        for f in readdir(libdir)
            if endswith(f, ".so")
                f_new = "$(f[1:end-3]).dylib"
                mv(joinpath(libdir, f), joinpath(libdir, f_new); force=true)

                # Convert all linkages from `.so` to `.dylib` endings:
                readmeta(joinpath(libdir, f_new)) do oh
                    for link in ObjectFile.path.(DynamicLinks(oh))
                        if endswith(link, ".so")
                            link_new = "$(link[1:end-3]).dylib"
                            run(ur, `$install_name_tool -change $(link) $(link_new) $(f_new)`, "/tmp/temp.log")
                        end
                    end
                end
            end
        end
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
