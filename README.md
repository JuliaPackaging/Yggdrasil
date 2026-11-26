# Yggdrasil

![Yggdrasil](https://user-images.githubusercontent.com/1282691/177174254-aa90664e-5c20-4ea3-9938-34de961dc198.png)

This repository contains recipes for building binaries for Julia packages using [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl).
Each recipe is a `build_tarballs.jl` file, in a directory named after the package under its initial letter, e.g. `Z/Zlib/build_tarballs.jl`.
When a pull request that changes a recipe is merged, CI builds it for every platform it requests and publishes the result as a JLL package.

## Contributing

The rules every recipe follows are in [AGENTS.md](AGENTS.md), together with a build script reference and common patterns.
It is written for AI coding agents, but applies to human contributors too.
[CONTRIBUTING.md](CONTRIBUTING.md) covers the contribution process: commit messages, special keywords, rebuilds and compat bounds.
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
cd Z/Zlib
julia --project build_tarballs.jl --verbose --debug x86_64-linux-gnu
```

The trailing triplet builds only that platform; omit it to build all of them.
`--debug` drops you into the build sandbox when a step fails.
Before merging, test the generated JLL as the [`testing-jll`](.agents/skills/testing-jll/SKILL.md) skill describes.

## Working with AI coding agents

Yggdrasil is set up for AI coding agents such as Claude Code, Codex and GitHub Copilot:

- [AGENTS.md](AGENTS.md) holds the rules for recipes, pull requests and security. Most agents read it automatically; point yours to it if it doesn't.
- [`.agents/skills/`](.agents/skills) holds topic guidance in the [Agent Skills](https://agentskills.io) format: MPI, CUDA, BLAS, libjulia/CxxWrap, Fortran, Rust, OpenMP, macOS and Windows recipes, JLL versioning, testing and reviewing. AGENTS.md lists when each one applies, and an agent reads the matching ones before working on a recipe.
- [`.agents/mcp-bb-sandbox/`](.agents/mcp-bb-sandbox) is `bb-sandbox`, an MCP server that gives an agent an interactive BinaryBuilder cross-compilation sandbox. [`.mcp.json`](.mcp.json) registers it for agents that read that file; its [README](.agents/mcp-bb-sandbox/README.md) explains the one-time setup.
- GitHub Copilot code review follows [`.github/instructions/code-review.instructions.md`](.github/instructions/code-review.instructions.md), which applies the same review checklist.

Before letting an agent work in this repository, read the [Security](AGENTS.md#security) section of AGENTS.md.
In short: `julia build_tarballs.jl` runs the whole recipe as Julia code on your machine, outside the sandbox, so build only recipes you trust.
Run an agent that handles other people's pull requests in a VM, container or separate account that holds none of your credentials, give it a fine-grained GitHub token limited to what its task needs, and keep its approval prompts on.

Review what your agent writes, and test the JLL before the pull request is merged: a successful build is not enough.

## Using the generated JLL packages

Merging a pull request generates a Julia package (a "JLL package") in the [JuliaBinaryWrappers organization](https://github.com/JuliaBinaryWrappers/) and registers it in the General registry.
It ships the binaries as [artifacts](https://pkgdocs.julialang.org/v1/artifacts/), so Julia code gets them with `using LibFoo_jll`, with no `Pkg.build()` step.
Read the [BinaryBuilder documentation](https://docs.binarybuilder.org/stable/jll/) to learn how to use JLL packages, and the blog post "[Pkg + BinaryBuilder -- The Next Generation](https://julialang.org/blog/2019/11/artifacts/)" for the background.
