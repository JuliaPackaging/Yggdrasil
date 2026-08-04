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

if [[ -z "${PROJECT:-}" ]]; then
    echo "ERROR: PROJECT must be set" >&2
    exit 1
fi

if [[ "${JULIA_PROJECT}" == *"/bb2_project"* ]]; then
    echo "--- Downloading BB2 artifacts"
    buildkite-agent artifact download --build "${BUILD_ID}" "${PROJECT}/products/*" "${YGGDRASIL_BASE}"

    echo "--- Registering BB2..."
    cd "${PROJECT}"
    julia "${JULIA_PROJECT}/register_package.jl" --verbose
    exit 0
fi

echo "--- Generating meta.json..."
cd "${PROJECT}"
GITHUB_TOKEN="" julia --compile=min ./build_tarballs.jl --meta-json="${NAME}.meta.json"

echo "--- Registering..."
julia "${JULIA_PROJECT}/register_package.jl" "${NAME}.meta.json" --verbose
