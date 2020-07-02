# This script downloads and bundles CA certificates from Amazon Web Services (AWS).
# Right now only the RDS root certificate is included, but more could be added in the future.

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "AmazonCACerts"
# Info here: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html
certificate_version = "2019"
certificate_filename = "rds-ca-$certificate_version-root.pem"
tarball_version = VersionNumber(certificate_version)

# Collection of sources required to build AmazonCACerts
sources = [
    FileSource("https://s3.amazonaws.com/rds-downloads/$certificate_filename",
    "d464378fbb8b981d2b28a1deafffd0113554e6adfb34535134f411bf3c689e73",
    filename="$certificate_filename")
]

# Bash recipe for building across all platforms
script = """
cd \$WORKSPACE/srcdir/
mkdir -p \$prefix/share
cp $certificate_filename \$prefix/share/$certificate_filename
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("share/$certificate_filename", :rds_ca_root_certificate)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, tarball_version, sources, script, platforms, products, dependencies)
