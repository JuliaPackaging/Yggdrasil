# Yggdrasil

![Yggdrasil](https://user-images.githubusercontent.com/1282691/177174254-aa90664e-5c20-4ea3-9938-34de961dc198.png)

This repository contains recipes for building binaries for Julia packages using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).
Each recipe is a `build_tarballs.jl` file, in a directory named after the package under its initial letter, e.g. `B/Bzip2/build_tarballs.jl`.
When a pull request that changes a recipe is merged, CI builds it for every platform it requests and publishes the result as a JLL package.

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) covers the contribution process: commit messages, special keywords, rebuilds and compat bounds.
The rules every recipe follows, a build script reference and common patterns are in [AGENTS.md](AGENTS.md), named so that coding agents find it too.
Before opening a pull request, check it against the [review checklist](.agents/skills/reviewing-prs/SKILL.md) maintainers use.

To build a newer version of an existing recipe, open a pull request that updates `version` and the source in its `build_tarballs.jl`: the commit hash and `tag` of a `GitSource`, or the URL and SHA256 of an `ArchiveSource`.
Sometimes more changes are needed, such as new dependencies or compat bounds; see [CONTRIBUTING.md](CONTRIBUTING.md#update-version-of-an-existing-recipe).
[This pull request](https://github.com/JuliaPackaging/Yggdrasil/pull/8833) is a typical version update.

To contribute a new recipe, start from an existing recipe for a similar package, or from one of the `H/HelloWorld*` recipes for your language's toolchain setup.
`BinaryBuilder.run_wizard()` can also generate a first recipe and open a pull request, but it does not expose every option a hand-written recipe can use.

[Buildkite CI](https://buildkite.com/julialang/yggdrasil) builds every recipe a pull request changes, for all its platforms.

### Building locally

Builds need an x86_64 host: the build environment consists of x86_64 Linux binaries, which run natively on Linux and under Docker on x86_64 macOS.
On other hosts, such as Apple silicon Macs, push your branch and let CI build it.
Use the Julia version named by `julia_version` in the repository's [`Manifest.toml`](Manifest.toml), which is what CI runs, and the repository's root project:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
cd B/Bzip2
julia --project build_tarballs.jl --verbose --debug x86_64-linux-gnu
```

The trailing triplet builds only that platform; omit it to build all of them.
`--debug` drops you into the build sandbox when a step fails.
Recipes that start with `using BinaryBuilder2` build with `.ci/bb2_project` instead of the root project.
Before merging, [test the generated JLL](.agents/skills/testing-jll/SKILL.md) on your own machine: a successful build is not enough.

### Using an AI coding agent

You don't need one to contribute. If you use one:

- Most agents read [AGENTS.md](AGENTS.md) automatically; point yours to it if it doesn't. It sends the agent to the topic guides in [`.agents/skills/`](.agents/skills) that match the recipe.
- [`.mcp.json`](.mcp.json) registers an optional MCP server that gives the agent an interactive build sandbox; its [README](.agents/mcp-bb-sandbox/README.md) explains the setup.
- Read the [Security](AGENTS.md#security) section of AGENTS.md first. `julia build_tarballs.jl` runs the whole recipe as Julia code on your machine, outside the sandbox, so build only recipes you trust, and run an agent that handles other people's pull requests somewhere that holds none of your credentials.
- A pull request is held to the same rules and review whoever wrote it, so check your agent's work before you open one.

## Using the generated JLL packages

Merging a pull request generates a Julia package (a "JLL package") in the [JuliaBinaryWrappers organization](https://github.com/JuliaBinaryWrappers/) and registers it in the General registry.
It ships the binaries as [artifacts](https://pkgdocs.julialang.org/v1/artifacts/), so Julia code gets them with `using LibFoo_jll`.
Read the [BinaryBuilder documentation](https://docs.binarybuilder.org/stable/jll/) to learn how to use JLL packages.
