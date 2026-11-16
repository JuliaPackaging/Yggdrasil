# Installs and loads JLLs on the running Julia, which may be any version from v1.3 on, so
# this script only uses the standard library.  It expects a fresh `JULIA_DEPOT_PATH` whose
# registries hold the JLLs; `General` is added unless the depot already holds it.
#
#   julia load_jlls.jl [--oldest-julia-only] <Name_jll>@<version>...
#
# With `--oldest-julia-only`, it skips the JLLs whose `julia` compat allows an older Julia
# than the running one (counting from v1.3), reading it from each JLL version in the
# depot's `packages` directory, where `export_depot.jl` put it.
#
# For each JLL it:
#  1. adds exactly that version to a fresh environment, failing if it cannot be resolved,
#  2. fails if Pkg ignored or overrode one of its `[compat]` entries, as it does for
#     standard libraries that the running Julia ships at another version,
#  3. loads it with `using`, which runs its `__init__()` (and so loads its libraries), and
#  4. `dlopen()`s each of its library products with `RTLD_NOW`, and checks that its
#     executable and file products exist.
# Each JLL is checked in its own Julia process, since a process can load only one version
# of a package.  Every JLL is checked even if an earlier one failed; the exit code is the
# number of failures.

import Pkg, Libdl
using Logging
using Pkg: PackageSpec
const TOML = Pkg.TOML

oldest_julia_only = "--oldest-julia-only" in ARGS
# Internal: check the one JLL given, in this process
single = "--single" in ARGS
jlls = Tuple{String,VersionNumber}[]
for arg in filter(a -> !startswith(a, "--"), ARGS)
    name, version = split(arg, "@")
    push!(jlls, (String(name), VersionNumber(version)))
end

# The oldest Julia version that the `julia` compat specifier allows, but at least v1.3, as
# `oldest_julia()` in `.buildkite/generator.jl` computes it to schedule this check.
function oldest_julia(julia_compat::AbstractString)
    spec = Pkg.Types.semver_spec(julia_compat)
    return max(minimum(VersionNumber(r.lower.t...) for r in spec.ranges), v"1.3")
end

function is_oldest_julia(name::String, version::VersionNumber)
    package_dir = joinpath(first(DEPOT_PATH), "packages", name)
    projects = [TOML.parsefile(joinpath(package_dir, slug, "Project.toml")) for slug in readdir(package_dir)]
    project = projects[findfirst(p -> VersionNumber(p["version"]) == version, projects)]
    oldest = oldest_julia(get(get(project, "compat", Dict()), "julia", "1"))
    return (oldest.major, oldest.minor) == (VERSION.major, VERSION.minor)
end

# Records every log message, at every level, while forwarding the ones a
# `ConsoleLogger` would show, so the Pkg output still appears in the CI log.
struct RecordingLogger <: AbstractLogger
    records::Vector{Any}
    console::AbstractLogger
end
Logging.min_enabled_level(::RecordingLogger) = Logging.Debug
Logging.shouldlog(::RecordingLogger, args...) = true
Logging.catch_exceptions(::RecordingLogger) = true
function Logging.handle_message(l::RecordingLogger, level, message, _module, group, id, file, line; kwargs...)
    push!(l.records, (level=level, message=string(message), _module=_module, kwargs=kwargs))
    if level >= Logging.Info
        Logging.handle_message(l.console, level, message, _module, group, id, file, line; kwargs...)
    end
end

# Log messages in which Pkg says it disregarded a `[compat]` entry of a project file, or
# of a package version that ended up installed.  While resolving, Pkg reports the latter
# for every version of every package it considers, so the others are dropped.
function ignored_compat_messages(records, installed::Dict{String,Any})
    function relevant(r)
        occursin(r"ignoring incompatible (stdlib )?compat"i, r.message) || return false
        kwargs = Dict(r.kwargs)
        haskey(kwargs, :package) || return true
        return string(get(installed, string(kwargs[:package]), nothing)) == string(get(kwargs, :version, ""))
    end
    return filter(relevant, records)
end

# The installed version of each package in the manifest of environment `env`, by name.
function installed_versions(env::String)
    manifest = TOML.parsefile(joinpath(env, "Manifest.toml"))
    # From manifest format v2.0 on, the packages are under `deps`
    packages = haskey(manifest, "manifest_format") ? manifest["deps"] : manifest
    return Dict{String,Any}(name => get(first(entries), "version", nothing) for (name, entries) in packages)
end

function host_triplet()
    if isdefined(Base, :BinaryPlatforms)
        return Base.BinaryPlatforms.triplet(Base.BinaryPlatforms.HostPlatform())
    end
    return Pkg.BinaryPlatforms.triplet(Pkg.BinaryPlatforms.platform_key_abi())
end

function project_toml(pkgid::Base.PkgId)
    entry = Base.locate_package(pkgid)
    entry === nothing && return nothing
    for candidate in (joinpath(dirname(dirname(entry)), "Project.toml"),
                      joinpath(dirname(dirname(entry)), "JuliaProject.toml"))
        isfile(candidate) && return TOML.parsefile(candidate)
    end
    return nothing
end

# The `[compat]` entries of `project` that the loaded version of the dependency violates.
function violated_compat(project::Dict)
    violations = String[]
    deps = get(project, "deps", Dict())
    for (name, spec) in get(project, "compat", Dict())
        name == "julia" && continue
        if !haskey(deps, name)
            continue
        end
        dep_project = project_toml(Base.PkgId(Base.UUID(deps[name]), name))
        dep_version = dep_project === nothing ? nothing : get(dep_project, "version", nothing)
        if dep_version === nothing
            push!(violations, "$(name): cannot determine the installed version (compat \"$(spec)\")")
        elseif !(VersionNumber(dep_version) in Pkg.Types.semver_spec(spec))
            push!(violations, "$(name) v$(dep_version) does not satisfy compat \"$(spec)\"")
        end
    end
    return violations
end

# The products of the JLL's build that its wrapper selected for this platform.
function check_products(mod::Module, jll_toml::Dict)
    problems = String[]
    if isdefined(mod, :is_available) && !Base.invokelatest(getfield(mod, :is_available))
        push!(problems, "no build for this platform ($(host_triplet()))")
        return problems, 0
    end
    num_checked = 0
    seen = Set{String}()
    for build in get(jll_toml, "builds", []), product in get(build, "products", [])
        name = product["name"]
        path_var = Symbol(name, "_path")
        (name in seen || !isdefined(mod, path_var)) && continue
        push!(seen, name)
        path = getfield(mod, path_var)
        num_checked += 1
        if product["type"] == "library"
            if get(product, "dont_dlopen", false)
                isfile(path) || push!(problems, "library $(name): $(path) does not exist")
                continue
            end
            handle = Libdl.dlopen(path, Libdl.RTLD_NOW; throw_error=false)
            if handle === nothing
                err = try
                    Libdl.dlopen(path, Libdl.RTLD_NOW)
                    ""
                catch e
                    sprint(showerror, e)
                end
                push!(problems, "library $(name): dlopen($(path), RTLD_NOW) failed: $(err)")
            end
        elseif !ispath(path)
            push!(problems, "$(product["type"]) $(name): $(path) does not exist")
        elseif product["type"] == "executable" && Sys.islinux()
            # Executables cannot be `dlopen()`'ed, so let the dynamic loader resolve
            # their libraries in the environment that the JLL runs them in.
            cmd = Base.invokelatest(getfield(mod, Symbol(name)))
            out = IOBuffer()
            success(pipeline(Cmd(`ldd $(path)`; env=cmd.env); stdout=out, stderr=out))
            missing_libs = filter(l -> occursin("not found", l), split(String(take!(out)), "\n"))
            if !isempty(missing_libs)
                push!(problems, "executable $(name): the dynamic loader cannot satisfy $(path):\n        " * join(strip.(missing_libs), "\n        "))
            end
        end
    end
    return problems, num_checked
end

function check_jll(name::String, version::VersionNumber)
    problems = String[]
    env = mktempdir()
    Pkg.activate(env)
    logger = RecordingLogger(Any[], ConsoleLogger(stderr))

    println("--- [$(VERSION)] $(name) v$(version): resolving")
    try
        with_logger(logger) do
            Pkg.add(PackageSpec(; name=name, version=version))
        end
    catch e
        push!(problems, "cannot be installed: $(sprint(showerror, e))")
        return problems
    end
    for r in ignored_compat_messages(logger.records, installed_versions(env))
        push!(problems, "Pkg ignored a compat entry: $(r.message) $(join(["$(k)=$(v)" for (k, v) in r.kwargs], " "))")
    end

    uuid = Base.UUID(TOML.parsefile(joinpath(env, "Project.toml"))["deps"][name])
    pkgid = Base.PkgId(uuid, name)
    project = project_toml(pkgid)
    if project === nothing || VersionNumber(project["version"]) != version
        push!(problems, "installed version $(project === nothing ? "?" : project["version"]) is not v$(version)")
    end

    println("--- [$(VERSION)] $(name) v$(version): loading")
    mod = try
        Base.require(pkgid)
    catch e
        push!(problems, "`using $(name)` failed: $(sprint(showerror, e))")
        return problems
    end
    project === nothing || append!(problems, violated_compat(project))

    jll_toml_path = joinpath(dirname(dirname(Base.locate_package(pkgid))), "JLL.toml")
    if isfile(jll_toml_path)
        product_problems, num_checked = check_products(mod, TOML.parsefile(jll_toml_path))
        append!(problems, product_problems)
        println("    checked $(num_checked) product(s)")
    end
    return problems
end

if !single && !isdir(joinpath(first(DEPOT_PATH), "registries", "General"))
    Pkg.Registry.add("General")
end

if single
    (name, version), = jlls
    problems = check_jll(name, version)
    if isempty(problems)
        println("+++ [$(VERSION)] $(name) v$(version): OK")
    else
        println("+++ [$(VERSION)] $(name) v$(version): FAILED")
        for p in problems
            println("    - ", p)
        end
    end
    exit(isempty(problems) ? 0 : 1)
end

if oldest_julia_only
    filter!(((name, version),) -> is_oldest_julia(name, version), jlls)
    if isempty(jlls)
        println("No JLL has Julia v$(VERSION.major).$(VERSION.minor) as its oldest compatible version")
        exit(1)
    end
end

failed = String[]
for (name, version) in jlls
    cmd = `$(Base.julia_cmd()) --startup-file=no --color=yes $(abspath(PROGRAM_FILE)) --single $(name)@$(version)`
    success(pipeline(ignorestatus(cmd); stdout=stdout, stderr=stderr)) || push!(failed, "$(name) v$(version)")
end
isempty(failed) || println("+++ [$(VERSION)] FAILED: ", join(failed, ", "))
exit(length(failed))
