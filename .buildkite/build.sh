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

# Clear secrets from environment
export BUILDKITE_PLUGIN_CRYPTIC_BASE64_SIGNED_JOB_ID_SECRET=""
export AWS_SECRET_ACCESS_KEY=""

# Add our shared depot cache to the end of JULIA_DEPOT_PATH which is already
# filled out by `julia-buildkite-plugin` to our agent/pipeline-specific depot path.
# Make sure to append a colon at the end to allow use of shipped stdlib caches.
export JULIA_DEPOT_PATH="${JULIA_DEPOT_PATH}:/sharedcache/depot:"
echo "--- Set JULIA_DEPOT_PATH to ${JULIA_DEPOT_PATH}"

echo "--- Setup Julia packages"
julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

# Parallel auditor can end up opening loads of files and causing
# "Too many open files" errors.  Increase the limit.
ulimit -n 65536

# Cleanup temporary things that might have been left-over
echo "--- Cleanup"
"${YGGDRASIL_BASE}/clean_builds.sh"
"${YGGDRASIL_BASE}/clean_products.sh"

echo "+++ Build"
# Start Julia with multiple threads to make auditor parallel.
julia --threads "${BINARYBUILDER_NPROC:-16}" ./build_tarballs.jl --verbose "$@"
