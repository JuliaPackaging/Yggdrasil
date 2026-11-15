# Update the GAP_pkg_* recipes to match GAP / GAP_lib
# Execute from the G/GAP_pkg/ directory, e.g.:
# julia --project=. update.jl
#
# Each package update is committed on its own branch `update/GAP_pkg_<name>`;
# at the end an octopus merge of all those branches is created on the
# original branch. To push all update branches:
#
#   git for-each-ref --format='%(refname:short)' 'refs/heads/update/GAP_pkg_*' | xargs -n1 git push -u origin

import Downloads
using GZip
using JSON
using SHA

gap_upstream_version = v"4.16.1"
gap_version = v"400.1600.100"
gap_lib_version = v"400.1600.100"

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

# check the current branch before committing anything
branch = readchomp(`git branch --show-current`)
if branch in ("main", "master")
    error("refusing to commit directly to $branch")
elseif isempty(branch)
    error("refusing to commit from a detached HEAD")
end

# download latest package-infos
download_with_sha256("https://github.com/gap-system/gap/releases/download/v$(gap_upstream_version)/package-infos.json.gz")

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
        VersionNumber(match(r"^gap_version = v\"([^\"]+)\""m, recipe).captures[1])
    catch
        gap_version
    end

    old_gap_lib_version = try
        VersionNumber(match(r"^gap_lib_version = v\"([^\"]+)\""m, recipe).captures[1])
    catch
        gap_lib_version
    end

    old_upstream_version = match(r"^upstream_version = v?\"([^\"]+)\""m, recipe).captures[1]
    offset = VersionNumber(match(r"^offset = v\"([^\"]+)\""m, recipe).captures[1])

    # new metadata from the GAP package registry
    if pkgname == "juliainterface"
        upstream_version = "0.17.4"
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
    upstream_changed = old_upstream_version != upstream_version
    if old_gap_version == gap_version && old_gap_lib_version == gap_lib_version && !upstream_changed
        # However, detect and warn if the archive changed with the version staying fixed.
        # That should never happen, but better be paranoid
        if pkgname != "juliainterface"
            @assert old_archive == archive
            @assert old_sha256 == sha256
        end
        @info "skipping $pkgname"
        return nothing
    elseif upstream_changed
        _old_upstream_version = VersionNumber(replace(old_upstream_version, "-" => "."))
        _upstream_version = VersionNumber(replace(upstream_version, "-" => "."))
        if _old_upstream_version.major != _upstream_version.major
            offset = v"0.0.0"
        else
            offset = VersionNumber(offset.major, 0, 0)
        end
    else
        offset = VersionNumber(offset.major, offset.minor, offset.patch + 1)
    end

    # update the metadata
    recipe = replace(recipe, r"^gap_version = v\"([^\"]+)\""m => "gap_version = v\"$gap_version\"")
    recipe = replace(recipe, r"^gap_lib_version = v\"[^\"]+\"" => "gap_lib_version = v\"$gap_lib_version\"")
    
    # update version
    recipe = replace(recipe, r"^upstream_version = v?\"[^\"]+\""m => "upstream_version = \"$upstream_version\"")
    recipe = replace(recipe, r"^offset = v\"[^\"]+\""m => "offset = v\"$offset\"")
    
    if pkgname == "juliainterface"
        # update GAP source & checksum for the host build (which is used for building the manual)
        gapsha256 = readline(Downloads.download("https://github.com/gap-system/gap/releases/download/v$(gap_upstream_version)/gap-$(gap_upstream_version).tar.gz.sha256"))
        recipe = replace(recipe, r"^gap_upstream_version = v\"([^\"]+)\""m => "gap_upstream_version = v\"$gap_upstream_version\"")
        recipe = replace(recipe, r"\"[0-9a-f]{64,64}\"" => "\"$gapsha256\"")
    else
        # update source & checksum
        recipe = replace(recipe, r"ArchiveSource\(\"([^\"]+)\"" => "ArchiveSource(\"$archive\"")
        recipe = replace(recipe, r"\"[0-9a-f]{64,64}\"" => "\"$sha256\"")
    end

    # write out the result
    @info "updating $pkgname"
    write(path, recipe)
    message = if upstream_changed
        "[GAP_pkg_$(pkgname)] Update to v$(upstream_version)"
    else
        "[GAP_pkg_$(pkgname)] Rebuild with GAP $(gap_upstream_version)"
    end

    # commit on a branch of its own; the pending changes are carried over by
    # `git switch`, so the base branch stays untouched
    topic = "update/$(dir)"
    run(`git switch -C $topic`)
    run(`git add -- $(dir)/`)
    run(`git commit -m $message -- $(dir)/`)
    run(`git switch $branch`)
    return topic
end

# get the names of all GAP package JLL recipes
dirs = readdir()
filter!(startswith("GAP_pkg_"), dirs)

topics = filter(!isnothing, map(update_gap_pkg_recipe, dirs))

# combine all update branches into a single octopus merge on the original
# branch; the branches touch disjoint directories, so this never conflicts
if isempty(topics)
    @info "nothing to do"
else
    message = "Update GAP packages for GAP $(gap_upstream_version)"
    run(`git merge --no-ff -m $message $(topics)`)
end

#=
# After running the above script, you can use the following commands to build and (locally) deploy the updated GAP_pkg_* JLLs:

export DEPLOY_NAMESPACE=$(gh api user -q ".login")

export PKGS=$(git log master..HEAD --pretty=format:%s | cut -d ' ' -f 1 | cut -c 2- | rev | cut -c 2- | rev | sort | uniq | while read -r PKG; do [ -d "$PKG" ] && echo "$PKG"; done)
session_started=0
for PKG in $(printf '%s\n' "$PKGS"); do
    sleep 1
    echo "Starting build of ${PKG}..."
    if [ $session_started -eq 0 ]; then
        tmux new-session -d -s GAP_pkg -c "$PKG" -n "$PKG" bash
        session_started=1
    else
        tmux new-window -d -t GAP_pkg: -c "$PKG" -n "$PKG" bash
    fi
    tmux send -t "$PKG" "julia --project=../../../.ci build_tarballs.jl --debug --verbose --deploy=$DEPLOY_NAMESPACE/${PKG}_jll.jl" C-m
done

if [ $session_started -eq 1 ]; then
    tmux attach-session -t GAP_pkg
fi


# To add all of the deployed JLLs to the current Julia environment, you can run the following commands in a Julia REPL:
julia --project -e "using Pkg; Pkg.add([
    PackageSpec(url=\"https://github.com/${DEPLOY_NAMESPACE}/\$(pkg)_jll.jl\")
    for pkg in split(\"${PKGS}\")
])"


=#
