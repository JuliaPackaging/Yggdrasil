#!/bin/bash
# Fail on error
set -e

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
# Start Julia with multiple thread to make auditor parallel.
julia --threads "${BINARYBUILDER_NPROC:-16}" ./build_tarballs.jl --verbose "${PLATFORM}"
