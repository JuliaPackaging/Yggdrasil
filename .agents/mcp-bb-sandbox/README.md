# bb-sandbox MCP server

`.agents/mcp-bb-sandbox/server.jl` is an MCP server, `bb-sandbox`, that launches and drives an interactive BinaryBuilder cross-compilation sandbox. Tools: `sandbox_start`, `sandbox_exec`, `sandbox_stop`, `sandbox_list`, `sandbox_str_replace_editor`.

Register it in your agent as a stdio server started from the checkout root (`.mcp.json` already does this for agents that read it):

```bash
julia --project=.agents/mcp-bb-sandbox .agents/mcp-bb-sandbox/server.jl
```

It runs on the `julia` found on `PATH`, which must be the version from [Prerequisites](../../AGENTS.md#prerequisites), and shells out to the checkout's root project for `build_tarballs.jl --debug`. Its `Manifest.toml` is not checked in, so it resolves against the latest `[sources]` branches. On a fresh checkout or worktree, instantiate both projects once, or the server fails to start with a missing-package error:

```bash
julia --project=.agents/mcp-bb-sandbox -e 'using Pkg; Pkg.instantiate()'
julia --project -e 'using Pkg; Pkg.instantiate()'
```

`sandbox_start` takes an absolute `build_tarballs_path`, so a server started in the main checkout can build a recipe in any worktree. The recipe then runs against the main checkout's root project, so keep that checkout's `master` up to date with `git pull`. To use the worktree's own project instead, start the agent from the worktree.
