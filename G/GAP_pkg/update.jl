# Update the GAP_pkg_* recipes to match GAP / GAP_lib

using JSON
import Downloads
using SHA
using GZip

upstream_version = v"4.14.0"
gap_version = v"400.1400.000"
gap_lib_version = v"400.1400.000"

function download_with_sha256(url)
    io = IOBuffer()
    Downloads.download(url * ".sha256", io)
    expected_shasum = String(take!(io))
    fname = basename(url)
    if isfile(fname)
        actual_shasum = bytes2hex(SHA.sha256(read(fname, String)))
        if expected_shasum == actual_shasum
            return
        end
        rm(fname)
    end
    Downloads.download(url, fname)
    actual_shasum = bytes2hex(SHA.sha256(read(fname, String)))
    if expected_shasum != actual_shasum
        error("expected checksum $(expected_shasum), actual checksum $(actual_shasum)")
    end
end

# download latest package-infos
download_with_sha256("https://github.com/gap-system/gap/releases/download/v$(upstream_version)/package-infos.json.gz")

# read the data
pkginfo = GZip.open(JSON.parse, "package-infos.json.gz")

#
function update_gap_pkg_recipe(dir)
    # extract package name
    pkgname = dir[9:end]
    @debug "checking $pkgname"

    # read existing recipe
    path = joinpath(dir, "build_tarballs.jl")
    recipe = read(path, String)

    # extract metadata from the recipe
    old_gap_version = try
        VersionNumber(match(r"gap_version = v\"([^\"]+)\"", recipe).captures[1])
    catch
        gap_version
    end

    old_gap_lib_version = try
        VersionNumber(match(r"gap_lib_version = v\"([^\"]+)\"", recipe).captures[1])
    catch
        gap_lib_version
    end

    old_upstream_version = match(r"upstream_version = v?\"([^\"]+)\"", recipe).captures[1]
    offset = VersionNumber(match(r"offset = v\"([^\"]+)\"", recipe).captures[1])

    # new metadata from the GAP package registry
    if pkgname == "juliainterface"
        upstream_version = "0.13.1"
        sha256 = "DUMMY"
    else
        meta = pkginfo[pkgname]
        upstream_version = meta["Version"]
        sha256 = meta["ArchiveSHA256"]
        archive = meta["ArchiveURL"] * first(split(meta["ArchiveFormats"]))
        # replace concrete version with placeholder, to reduce diffs in update
        archive = replace(archive, upstream_version => "\$(upstream_version)")
    end

    m = match(r"ArchiveSource\(\"([^\"]+)\",\n *\"([0-9a-f]+)\"\)", recipe)
    if m !== nothing
        old_archive, old_sha256 = m.captures
    else
        @assert pkgname == "juliainterface"
    end

    # if there are no changes, do nothing
    if old_gap_version == gap_version && old_gap_lib_version == gap_lib_version && old_upstream_version == upstream_version
        # However, detect and warn if the archive changed with the version staying fixed.
        # That should never happen, but better be paranoid
        if pkgname != "juliainterface"
            @assert old_archive == archive
            @assert old_sha256 == sha256
        end
        @info "skipping $pkgname"
        return
    elseif old_upstream_version != upstream_version
        offset = v"0.0.0"
    else
        offset = VersionNumber(offset.major, offset.minor, offset.patch + 1)
    end

    # update the metadata
    recipe = replace(recipe, r"gap_version = v\"([^\"]+)\"" => "gap_version = v\"$gap_version\"")
    recipe = replace(recipe, r"gap_lib_version = v\"[^\"]+\"" => "gap_lib_version = v\"$gap_lib_version\"")

    # update version
    recipe = replace(recipe, r"upstream_version = v?\"[^\"]+\"" => "upstream_version = \"$upstream_version\"")
    recipe = replace(recipe, r"offset = v\"[^\"]+\"" => "offset = v\"$offset\"")

    if pkgname != "juliainterface"
        # update source & checksum
        recipe = replace(recipe, r"ArchiveSource\(\"([^\"]+)\"" => "ArchiveSource(\"$archive\"")
        recipe = replace(recipe, r"\"[0-9a-f]{64,64}\"" => "\"$sha256\"")
    end

    # write out the result
    @info "updating $pkgname"
    write(path, recipe)
end

# get the names of all GAP package JLL recipes
dirs = readdir()
filter!(startswith("GAP_pkg_"), dirs)

for dir in dirs
    update_gap_pkg_recipe(dir)
end
