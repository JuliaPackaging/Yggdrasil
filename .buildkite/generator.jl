const DEBUG = !haskey(ENV, "BUILDKITE")

include("utils.jl")

# Normally we look at the last pushed commit
COMPARE_AGAINST="HEAD~1"

# Keyword to be used in the commit message to skip a rebuild
# TODO: Not run generator? Add to bk pipeline directly
const SKIP_BUILD_COOKIE="[skip build]"

# This variable will tell us whether we want to skip the build
SKIP_BUILD=false

const IS_PR = get(ENV, "BUILDKITE_PULL_REQUEST", "false") != "false"

exec(cmd) = @assert success(pipeline(cmd, stderr=stderr, stdout=stdout))

if IS_PR
    # If we're on a PR though, we look at the entire branch at once
    BASE_BRANCH = get(ENV, "BUILDKITE_PULL_REQUEST_BASE_BRANCH", "master")
    @assert !isempty(BASE_BRANCH)

    PR_NUMBER = parse(Int, ENV["BUILDKITE_PULL_REQUEST"])
    TARGET_BRANCH = "remotes/origin/$(BASE_BRANCH)"
    COMPARE_AGAINST = chomp(read(`git merge-base --fork-point $(TARGET_BRANCH) HEAD`, String))

    exec(`git fetch origin "refs/pull/$(PR_NUMBER)/head:refs/remotes/origin/pr/$(PR_NUMBER)"`)

    #if [[ "$(git show -s --format=%B origin/pr/$(System.PullRequest.PullRequestNumber))" == *"${SKIP_BUILD_COOKIE}"* ]]; then
    #   SKIP_BUILD="true"
    #fi
else
    # if [[ "$(git show -s --format=%B)" == *"${SKIP_BUILD_COOKIE}"* ]]; then
    #   SKIP_BUILD="true"
    # fi
end

using Pkg, Downloads, Dates, SHA

if !isnothing(Pkg.pkg_server())
    resp = try
        Downloads.request("$(Pkg.pkg_server())/registries")
    catch e
        # Let us know the download of the registry went wrong, but do not hard fail
        @error "Could not download the registry" exception=(e, catch_backtrace())
        exit(0)
    end
    last_mod_idx = findfirst(h -> first(h) == "last-modified", resp.headers)
    msg = "PkgServer: " * resp.url
    delay = if !isnothing(last_mod_idx)
        last_mod = last(resp.headers[last_mod_idx])
        msg *= " -- last updated: " * last_mod
        # Manually strip the "GMT" timezone and hope it never changes.
        # Do not error out if parsing fails.
        dt = tryparse(DateTime, replace(last_mod, " GMT"=>""), dateformat"e, d u y H:M:S")
        # If parsing did fail, set the delay to 0.
        isnothing(dt) ? Second(0) : now(UTC) - dt
    else
        Second(0)
    end
    delay > Second(0) && (msg *= " (" * string(Dates.canonicalize(round(delay, Second))) * " ago)")
    @info(msg)
    annotate(msg, style="info", context="pkg")
    tolerance = Hour(1)
    if delay > tolerance
        @warn "The PkgServer registry is older than $(tolerance)"
        annotate("The PkgServer registry is older than $(tolerance)", style = "warning", context="pkg")
    end
end

# Get the directories holding changed files
# 1. All changed files
# 2. Only files in directories
# 3. dirname
# 4. Unique the directories
PROJECTS = readlines(
    pipeline(`git diff-tree --no-commit-id --name-only -r HEAD $(COMPARE_AGAINST)`,
             `grep -E ".+/.+"`))
PROJECTS = map(dirname, PROJECTS) |> unique!

# If there are scary projects we need to exclude, we list them here. (Used to contain `LLVM`)
EXCLUDED_NAMES = String[]

# This is the dynamic mapping we're going to build up, if it's empty we don't do anything
PROJECTS_ACCEPTED = Set{String}()
for PROJECT in PROJECTS
    println("Considering ", PROJECT)

    # Only accept things that contain a `build_tarballs.jl`
    while !ispath(joinpath(PROJECT, "build_tarballs.jl")) && !isempty(PROJECT)
        println(" --> $(PROJECT) does not contain a build_tarballs.jl, moving up a directory")
        PROJECT = dirname(PROJECT)
    end

    if isempty(PROJECT)
        println(" --> Skipping as we could not find a build_tarballs.jl")
        continue
    end

    # Ignore RootFS stuff, we'll do that manually
    if startswith(PROJECT, "0_RootFS/")
        println(" --> Skipping as it's within 0_RootFS/")
        continue
    end

    NAME = basename(PROJECT)
    # Ignore stuff in our excluded projects
    if NAME in EXCLUDED_NAMES
        println(" --> Skipping as it's excluded")
        continue
    end

    # Otherwise, emit a build with `PROJECT` set to `${PROJECT}`
    println(" --> Accepted!")
    push!(PROJECTS_ACCEPTED, PROJECT)
end

if isempty(PROJECTS_ACCEPTED)
    annotate("No projects accepted", style="success")
    exit()
end

YGGDRASIL_BASE = dirname(@__DIR__)
julia(args) = `$(Base.julia_cmd()) --project=$(YGGDRASIL_BASE)/.ci $args`

# Next, we're going to ensure that our BB is up to date and precompiled
julia(`-e "import Pkg; Pkg.instantiate(); Pkg.precompile()"`) |> exec

# We're going to snarf out the BB and BBB tree hashes and combine them to be used later in our build cache
BB_HASH = julia(```
    -e "using Pkg, SHA; \
        gethash(uuid) = collect(Pkg.Types.Context().env.manifest[Pkg.Types.UUID(uuid)].tree_hash.bytes); \
        print(bytes2hex(sha256(vcat( \
            gethash(\"7f725544-6523-48cd-82d1-3fa08ff4056e\"), \
            gethash(\"12aac903-9f7c-5d81-afc2-d9565ea332ae\"), \
        ))));"
```) |> cmd -> read(cmd, String)

# Next, for each project, download its sources. We do this by generating meta.json
# files, then parsing them with `download_sources.jl`

TEMP = mktempdir()

for PROJECT in PROJECTS_ACCEPTED
    NAME = basename(PROJECT)

    # We always invoke a `build_tarballs.jl` file from its own directory
    cd(PROJECT) do
        println("Generating meta.json...")
        JSON_PATH = "$(TEMP)/$(NAME).meta.json"
        julia(`--compile=min ./build_tarballs.jl --meta-json="$(JSON_PATH)"`) |> exec

        println("Downloading sources...")
        julia(`$(YGGDRASIL_BASE)/.ci/download_sources.jl "$(JSON_PATH)" $(TEMP)/$(NAME).platforms.list`) |> exec
    end
end

println("Determining builds to queue...")
for PROJECT in PROJECTS_ACCEPTED
    NAME = basename(PROJECT)

    # "project source hash" is a combination of meta.json (to absorb
    # changes from include()'ing a `common.jl`) as well as the entire
    # tree the project lives in (to absorb changes from patches)
    # In order to support symlinked directories as dependencies we calculate
    # the tree hash on a TMP_PROJECT using `cp -RL` to resolve the symlink and
    # hash the actual content.

    TMP_PROJECT = mktempdir()
    exec(`cp -RL $(PROJECT) $(TMP_PROJECT)`)
    TREE_HASH = julia(`-e "using Pkg; print(bytes2hex(Pkg.GitTools.tree_hash(\"$(TMP_PROJECT)\")))"`) |> cmd->read(cmd, String)
    META_HASH = open(io->sha256(io), "$(TEMP)/$(NAME).meta.json") |> bytes2hex
    PROJ_HASH = sha256(TREE_HASH*META_HASH) |> bytes2hex

    # Load in the platforms
    PLATFORMS = split(read(joinpath(TEMP, "$(NAME).platforms.list"), String))
    if isempty(PLATFORMS)
        annotate("Unable to determine the proper platforms for $(NAME)", style="error", context=NAME)
        continue
    end

    # That's everything we need to know for `jll_init_step` and `register_step` later on down

    # Some debugging info
    println(" ---> $(NAME): $(BB_HASH)/$(PROJ_HASH) ($(TREE_HASH) + $(META_HASH))")

    # For `build_step`, we need to know more...
    BUILD_STEPS = Any[]
    for PLATFORM in PLATFORMS
        # if [[ "${SKIP_BUILD}" == "true" ]]; then
        #     echo "The commit messages contains ${SKIP_BUILD_COOKIE}, skipping build"
        #     break
        # fi

        # Here, we hit the build cache to see if we can skip this particular combo
        CACHE_URL = "https://julia-bb-buildcache.s3.amazonaws.com/$(BB_HASH)/$(PROJ_HASH)/$(PLATFORM).tar.gz"
        CURL_HTTP_CODE = read(`curl --output /tmp/curl_$(PROJ_HASH)_$(PLATFORM).log --silent --include --HEAD "$(CACHE_URL)" --write-out '%{http_code}'`, String)
        if CURL_HTTP_CODE == "200"
            println("    $(PLATFORM): skipping, existant")
            continue
        end
        println("    $(PLATFORM): building")

        # # Debugging: let's see why `curl` failed:
        # echo "CACHE_URL: ${CACHE_URL}"
        # cat /tmp/curl_${PROJ_HASH}_${PLATFORM}.log || true

        # Otherwise, emit the build
        push!(BUILD_STEPS, build_step(NAME, PLATFORM, PROJECT, BB_HASH, PROJ_HASH))
        rm("/tmp/curl_$(PROJ_HASH)_$(PLATFORM).log")
    end

    project_info = (; NAME, PROJECT, BB_HASH, PROJ_HASH)

    definition = Dict(
        :steps => [
            jll_init_step(NAME, PROJECT, BB_HASH, PROJ_HASH),
            wait_step(),
            group_step(NAME, BUILD_STEPS),
            wait_step(),
            register_step(NAME, PROJECT, BB_HASH, PROJ_HASH)
        ]
    )
    upload_pipeline(definition)
end
