#!/usr/bin/env julia
#
# Helper script to launch an interactive BinaryBuilder sandbox shell.
# Called by the MCP server as a subprocess with piped IO.
#
# Usage (from the checkout root): julia --project .agents/mcp-bb-sandbox/run_shell.jl <platform>
#
# The sandbox's stdin/stdout are inherited from this process,
# so the MCP server can communicate with the shell via pipes.

using BinaryBuilder
using BinaryBuilderBase

platform_str = ARGS[1]

platform = parse(BinaryBuilderBase.Platform, platform_str)
# runshell mounts the working directory read-write at /workspace, and the sandbox has
# network access, so give it an empty scratch directory rather than the checkout.
cd(mktempdir())

BinaryBuilder.runshell(platform)
