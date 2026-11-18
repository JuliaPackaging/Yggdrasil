#!/bin/bash
# Installs and loads JLLs on the Julia in `PATH`, from the depot that `package_jlls.sh`
# packed, next to a fresh copy of `General`.  With `--oldest-julia-only`, only the JLLs
# whose `julia` compat allows no older Julia.
#
#   load_check.sh <jll-depot.tar.gz> [--oldest-julia-only]
set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUNDLE="$1"
shift

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
tar -xzf "${BUNDLE}" -C "${WORK_DIR}"
DEPOT="${WORK_DIR}/jll-depot"

echo "--- Cloning General"
# A plain directory rather than a git repository, so that no Julia version tries to update it
git clone --quiet --depth=1 https://github.com/JuliaRegistries/General "${DEPOT}/registries/General"
rm -rf "${DEPOT}/registries/General/.git"

mapfile -t JLLS < "${DEPOT}/jlls.txt"
# Only the JLLs' own registry provides them: before v1.5, Pkg applies the version ranges in
# `General`'s `Compat.toml` and `Deps.toml` to the versions of other registries too.
for NAME in $(printf '%s\n' "${JLLS[@]%@*}" | sort -u); do
    grep -v -F "name = \"${NAME}\"," "${DEPOT}/registries/General/Registry.toml" > "${WORK_DIR}/Registry.toml"
    mv "${WORK_DIR}/Registry.toml" "${DEPOT}/registries/General/Registry.toml"
done

# Besides that depot, only Julia's bundled depot, with its precompiled standard libraries
BUNDLED_DEPOT="$(julia --startup-file=no -e 'print(abspath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')"
export JULIA_DEPOT_PATH="${DEPOT}:${BUNDLED_DEPOT}"
export JULIA_PKG_SERVER=""
export JULIA_PKG_GC_AUTO=0
julia --startup-file=no --color=yes "${SCRIPT_DIR}/load_jlls.jl" "$@" "${JLLS[@]}"
