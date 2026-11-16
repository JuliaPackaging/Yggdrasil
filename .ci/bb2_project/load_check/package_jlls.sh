#!/bin/bash
# Registers the BinaryBuilder2 packages that the given projects build, in that order, into
# a throwaway local universe without deploying them anywhere, and packs their JLLs, with
# their artifacts and a registry for them, into a depot, `jll-depot.tar.gz` (see
# `export_depot.jl`), for `load_check.sh`.  On Buildkite, the build products are first
# downloaded from the build steps.
#
#   package_jlls.sh <project>...
set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
YGGDRASIL_BASE="$( cd -- "${SCRIPT_DIR}/../../.." &> /dev/null && pwd )"
export JULIA_PROJECT="${YGGDRASIL_BASE}/.ci/bb2_project"
export JULIA_PKG_GC_AUTO=0
# BinaryBuilder2 commits the JLLs and the universe's registry
export GIT_AUTHOR_NAME="jlbuild" GIT_COMMITTER_NAME="jlbuild"
export GIT_AUTHOR_EMAIL="juliabuildbot@gmail.com" GIT_COMMITTER_EMAIL="juliabuildbot@gmail.com"

echo "--- Setup Julia packages"
julia --color=yes -e 'import Pkg; Pkg.instantiate(); Pkg.precompile()'

cd "${YGGDRASIL_BASE}"
if [[ -n "${BUILDKITE:-}" ]]; then
    echo "--- Downloading the build products"
    for PROJ in "$@"; do
        buildkite-agent artifact download "${PROJ}/products/*" "${YGGDRASIL_BASE}"
    done
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
echo "--- Registering $*"
BB2_EXPORT_DIR="${WORK_DIR}/jll-depot" julia --color=yes "${JULIA_PROJECT}/register_package.jl" "$@"
tar -czf jll-depot.tar.gz -C "${WORK_DIR}" jll-depot
echo "Wrote ${YGGDRASIL_BASE}/jll-depot.tar.gz:"
cat "${WORK_DIR}/jll-depot/jlls.txt"
