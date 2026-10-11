#!/bin/bash
# Fail on error
set -e

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
YGGDRASIL_BASE="$(dirname "${SCRIPT_DIR}")"
export JULIA_PROJECT="${JULIA_PROJECT:-${YGGDRASIL_BASE}/${JULIA_PROJECT_RELATIVE:-/foo}}"

# Early-exit if someone is blindly running this manually
if [[ ! -d "${JULIA_PROJECT:-}" ]]; then
    echo "ERROR: Must set JULIA_PROJECT to one of:" >&2
    echo "  - ${YGGDRASIL_BASE}/.ci/bb1_project" >&2
    echo "  - ${YGGDRASIL_BASE}/.ci/bb2_project" >&2
    echo "Current value: '${JULIA_PROJECT:-}'" >&2
    exit 1
fi

echo "--- Setup Julia packages"
GITHUB_TOKEN="" REGISTRY_GITHUB_TOKEN="" julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

if [[ -z "${PROJECT:-}" ]]; then
    echo "ERROR: PROJECT must be set" >&2
    exit 1
fi

# LibGit2 (used by `push_jll_package`) only reads the commit identity from git config, not env vars
echo "--- Setting up git"
git config --global user.name "jlbuild"
git config --global user.email "juliabuildbot@gmail.com"

if [[ "${JULIA_PROJECT}" == *"/bb2_project"* ]]; then
    echo "--- [BB2] Downloading artifacts..."
    buildkite-agent artifact download --build "${BUILD_ID}" "${PROJECT}/products/*" "${YGGDRASIL_BASE}"

    echo "--- [BB2] Registering ${NAME}..."
    cd "${PROJECT}"
    julia "${JULIA_PROJECT}/register_package.jl" --verbose
    exit 0
fi

echo "--- [BB1] Generating meta.json..."
cd "${PROJECT}"
GITHUB_TOKEN="" REGISTRY_GITHUB_TOKEN="" julia --compile=min ./build_tarballs.jl --meta-json="${NAME}.meta.json"

echo "--- [BB1] Registering ${NAME}..."
# BinaryBuilder bounds concurrent tarball inspection to avoid exhausting TMPDIR.
julia --threads 8 "${JULIA_PROJECT}/register_package.jl" "${NAME}.meta.json" --verbose
