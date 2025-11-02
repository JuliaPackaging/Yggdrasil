# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
#
# This package repackages the `openssl` CLI executable from OpenSSL_jll.
# 
# Background: Starting with Julia 1.12, OpenSSL_jll became a standard library
# with the `openssl` executable removed to minimize the standard library footprint.
# This separate package provides the CLI tool for users who need it.
#
# Rationale: OpenSSL's build system does not support building the CLI application
# separately from the libraries. The `build_apps` make target has hard dependencies
# that trigger a full library rebuild. Since OpenSSL builds are time-consuming
# (typically several minutes even on modern hardware), and OpenSSL_jll already
# provides a complete build including the executable, we simply extract and
# repackage the CLI tool rather than rebuilding everything from source.
using BinaryBuilder

name = "OpenSSL_CLI"
version = v"3.5.1"

# No sources needed - we're repackaging from OpenSSL_jll
sources = []

script = raw"""
# Copy the openssl executable from OpenSSL_jll
install -Dvm 755 "${bindir}/openssl${exeext}" "${bindir}/openssl${exeext}"

# Install the license from OpenSSL_jll
install_license ${prefix}/share/licenses/OpenSSL/LICENSE*
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("openssl", :openssl),
]

dependencies = [
    Dependency("OpenSSL_jll"; compat="~$(version.major).$(version.minor).$(version.patch)"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
