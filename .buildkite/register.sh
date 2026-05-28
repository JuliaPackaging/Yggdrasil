#!/bin/bash
# Fail on error
set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
YGGDRASIL_BASE="$(dirname "${SCRIPT_DIR}")"
JULIA_PROJECT="${YGGDRASIL_BASE}/${JULIA_PROJECT:-/foo}"

# Early-exit if someone is blindly running this manually
if [[ ! -d "${JULIA_PROJECT:-}" ]]; then
    echo "ERROR: Must set JULIA_PROJECT to one of:" >&2
    echo "  - ${YGGDRASIL_BASE}/.ci/bb1_project" >&2
    echo "  - ${YGGDRASIL_BASE}/.ci/bb2_project" >&2
    exit 1
fi

echo "--- Setup Julia packages"
GITHUB_TOKEN="" julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

echo "--- Setting up git"
git config --global user.name "jlbuild"
git config --global user.email "juliabuildbot@gmail.com"

echo "--- Registering..."
julia ${JULIA_PROJECT}/register_package.jl "${META_JSON:-}" --verbose
