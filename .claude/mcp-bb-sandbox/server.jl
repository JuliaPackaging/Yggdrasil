#!/usr/bin/env julia
#
# BinaryBuilder Sandbox MCP Server for Yggdrasil
#
# Thin wrapper around ClaudeMCPTools that registers a sessioned bash tool
# configured to launch BinaryBuilder sandbox sessions.
#
# Dependencies: ClaudeMCPTools (from .ci project, activated via --project flag in .mcp.json)

using ClaudeMCPTools

# ═══════════════════════════════════════════════════════════════
# Constants
# ═══════════════════════════════════════════════════════════════

const SERVER_DIR = @__DIR__
const PROJECT_ROOT = dirname(dirname(SERVER_DIR))  # .claude/mcp-bb-sandbox -> .claude -> root
const CI_PROJECT = joinpath(PROJECT_ROOT, ".ci")
const RUN_SHELL_SCRIPT = joinpath(SERVER_DIR, "run_shell.jl")

const JULIA_CMD = ["julia", "+1.12"]

function log_msg(msg)
    println(stderr, "[bb-sandbox] ", msg)
    flush(stderr)
end

# ═══════════════════════════════════════════════════════════════
# BinaryBuilder-specific session start command
# ═══════════════════════════════════════════════════════════════

function make_sandbox_cmd(params::AbstractDict)
    platform = get(params, "platform", "x86_64-linux-gnu")
    bt_path = get(params, "build_tarballs_path", nothing)
    debug_mode = get(params, "debug_mode", "end")

    metadata = Dict{String,Any}("platform" => platform)

    local cmd
    if bt_path !== nothing
        bt_path = abspath(bt_path)
        isfile(bt_path) || error("build_tarballs.jl not found: $bt_path")
        bt_dir = dirname(bt_path)
        metadata["build_tarballs_path"] = bt_path
        cmd = Cmd(`$(JULIA_CMD) --project=$CI_PROJECT $bt_path --debug=$debug_mode $platform`; dir=bt_dir)
        log_msg("Using build_tarballs: $bt_path (debug=$debug_mode)")
    else
        cmd = Cmd(`$(JULIA_CMD) --project=$CI_PROJECT $RUN_SHELL_SCRIPT $platform $PROJECT_ROOT`; dir=PROJECT_ROOT)
    end

    return (cmd, metadata)
end

# ═══════════════════════════════════════════════════════════════
# Session formatting
# ═══════════════════════════════════════════════════════════════

function format_sandbox_session(session::BashSession)
    uptime = round(Int, time() - session.created_at)
    running = process_running(session.process)
    platform = get(session.metadata, "platform", "unknown")
    bt = get(session.metadata, "build_tarballs_path", nothing)
    bt_str = bt !== nothing ? " | Build: $bt" : ""
    return "- ID: $(session.id) | Platform: $platform | Status: $(running ? "running" : "exited") | Uptime: $(uptime)s$bt_str"
end

# ═══════════════════════════════════════════════════════════════
# Server setup
# ═══════════════════════════════════════════════════════════════

manager = SessionManager(make_sandbox_cmd;
    log=log_msg,
    format_session=format_sandbox_session,
    ready_timeout_s=300.0)

server = MCPServer(;
    name="bb-sandbox",
    version="1.0.0",
    instructions="BinaryBuilder sandbox manager for Yggdrasil. " *
        "Use sandbox_start to launch an interactive cross-compilation environment, " *
        "sandbox_exec to run commands inside it, and sandbox_stop when done.")

# Register sessioned bash tools for sandbox management
register_sessioned_bash!(server, manager;
    prefix="sandbox",
    start_description="""Launch a new BinaryBuilder sandbox session for interactive cross-compilation debugging.

Returns a session_id to use with sandbox_exec. The sandbox provides a full BinaryBuilder environment with cross-compilation toolchains, compilers (CC, CXX, FC), and standard environment variables (prefix, WORKSPACE, target, libdir, bindir, etc.).

The session is persistent: working directory changes, environment variable modifications, and other shell state carry over between sandbox_exec calls.

Starting a session may take 1-3 minutes on first run as compiler shards are downloaded and mounted.""",
    exec_description="""Execute a bash command inside a running BinaryBuilder sandbox session.

The session is persistent - working directory and environment changes carry over between commands. Both stdout and stderr are captured and returned interleaved.

Inside the sandbox you have access to cross-compilers (\$CC, \$CXX, \$FC), the target platform triplet (\$target), install prefix (\$prefix), and all standard BinaryBuilder environment variables.""",
    stop_description="Stop a running BinaryBuilder sandbox session and clean up resources.",
    list_description="List all active BinaryBuilder sandbox sessions with their IDs, platforms, and uptime.",
    start_extra_properties=Dict{String,Any}(
        "platform" => Dict{String,Any}(
            "type" => "string",
            "description" => "Target platform triplet. Examples: 'x86_64-linux-gnu', 'aarch64-linux-musl', 'x86_64-w64-mingw32', 'x86_64-apple-darwin14', 'aarch64-apple-darwin20'. Defaults to 'x86_64-linux-gnu'.",
        ),
        "build_tarballs_path" => Dict{String,Any}(
            "type" => "string",
            "description" => "Optional absolute or relative path to a build_tarballs.jl file. When specified, the build script runs with the selected debug_mode and then drops into an interactive shell. Sources are downloaded and extracted into the workspace.",
        ),
        "debug_mode" => Dict{String,Any}(
            "type" => "string",
            "description" => "Debug mode when build_tarballs_path is set. 'end' (default): run the full build script, then drop into a shell to inspect results. 'begin': drop into a shell before the build script runs, so you can execute build steps manually.",
            "enum" => Any["begin", "end"],
        ),
    ))

# Register sessioned str_replace_editor for editing files inside the sandbox
register_tool!(server, "sandbox_str_replace_editor",
    SessionedStrReplaceEditorTool(manager, "sandbox_str_replace_editor",
        """View, create, and edit files inside a running BinaryBuilder sandbox session.

Uses the same command interface as str_replace_editor (view/str_replace/create) but operates on files inside the sandbox filesystem rather than the host. Requires a session_id from sandbox_start.

Paths should be absolute paths inside the sandbox (e.g. /workspace/srcdir/..., \$prefix/lib/...)."""))

# Clean shutdown
atexit() do
    stop_all_sessions(manager)
    log_msg("MCP server shut down.")
end

# Start
log_msg("MCP server starting (pid=$(getpid()))")
log_msg("Project root: $PROJECT_ROOT")
run_stdio_server(server)
