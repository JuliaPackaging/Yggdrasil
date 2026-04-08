#!/usr/bin/env julia
#
# Helper script to launch an interactive BinaryBuilder sandbox shell.
# Called by the MCP server as a subprocess with piped IO.
#
# Usage: julia --project=.ci run_shell.jl <platform> [workdir]
#
# The sandbox's stdin/stdout are inherited from this process,
# so the MCP server can communicate with the shell via pipes.

using BinaryBuilder
using BinaryBuilderBase

platform_str = ARGS[1]
workdir = length(ARGS) >= 2 ? ARGS[2] : pwd()

platform = parse(BinaryBuilderBase.Platform, platform_str)
cd(workdir)

BinaryBuilder.runshell(platform)
