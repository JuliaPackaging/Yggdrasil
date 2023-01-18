#!/bin/bash
# Fail on error
set -e

export JULIA_PROJECT="${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci"

echo "--- Setup Julia packages"
julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

# Cleanup temporary things that might have been left-over
echo "--- Cleanup"
./clean_builds.sh
./clean_products.sh

echo "+++ Build"
cd "${PROJECT}"
julia ./build_tarballs.jl --verbose "${PLATFORM}"
