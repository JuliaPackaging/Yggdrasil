#!/bin/bash
# Fail on error
set -e

export JULIA_PROJECT="${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci"

echo "--- Setup Julia packages"
GITHUB_TOKEN="" julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

cd "${PROJECT}"
echo "--- Generating meta.json..."
GITHUB_TOKEN="" julia --compile=min ./build_tarballs.jl --meta-json=${NAME}.meta.json

echo "--- Setting up git"
git config --global user.name "jlbuild"
git config --global user.email "juliabuildbot@gmail.com"

echo "--- Registering ${NAME}..."
julia ${BUILDKITE_BUILD_CHECKOUT_PATH}/.ci/register_package.jl "${NAME}.meta.json" --verbose

