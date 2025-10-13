#!/bin/bash
# Fail on error
set -e

# Clear secrets from environment
export BUILDKITE_PLUGIN_CRYPTIC_BASE64_SIGNED_JOB_ID_SECRET=""
export AWS_SECRET_ACCESS_KEY=""

export JULIA_PROJECT="${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci"

# Add our shared depot cache to the end of JULIA_DEPOT_PATH which is already
# filled out by `julia-buildkite-plugin` to our agent/pipeline-specific depot path.
export JULIA_DEPOT_PATH="${JULIA_DEPOT_PATH}:/sharedcache/depot"

echo "--- Setup Julia packages"
julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

# Cleanup temporary things that might have been left-over
echo "--- Cleanup"
./clean_builds.sh
./clean_products.sh

echo "+++ Build"
cd "${PROJECT}"

# Parallel auditor can end up opening loads of files and causing
# "Too many open files" errors.  Increase the limit.
ulimit -n 65536

# Start Julia with multiple thread to make auditor parallel.
julia --threads "${BINARYBUILDER_NPROC:-16}" ./build_tarballs.jl --verbose "${PLATFORM}"
