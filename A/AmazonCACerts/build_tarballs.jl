# This script downloads and bundles CA certificates from Amazon Web Services (AWS).
# Currently this makes the following three .pem files available:
# - Amazon root certificate: to use SSL/TLS with various AWS services, including serverless RDS
# - RDS root certificate: to use SSL/TLS with non-serverless RDS (https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html)
# - A combined .pem file of the two certificates above, to make it easier to use SSL/TLS with either serverless or non-serverless RDS

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "AmazonCACerts"

amazon_root_certificate_filename = "AmazonRootCA1.pem"
rds_root_certificate_version = "2019"
rds_root_certificate_filename = "rds-ca-$rds_root_certificate_version-root.pem"
combined_root_certificates_filename = "combined-amazon-root-ca.pem"

tarball_version = VersionNumber("$rds_root_certificate_version.1")

# Collection of sources required to build AmazonCACerts
sources = [
    FileSource("https://www.amazontrust.com/repository/$amazon_root_certificate_filename",
    "2c43952ee9e000ff2acc4e2ed0897c0a72ad5fa72c3d934e81741cbd54f05bd1",
    filename="$amazon_root_certificate_filename"),

    FileSource("https://s3.amazonaws.com/rds-downloads/$rds_root_certificate_filename",
    "d464378fbb8b981d2b28a1deafffd0113554e6adfb34535134f411bf3c689e73",
    filename="$rds_root_certificate_filename")
]

# Bash recipe for building across all platforms
script = """
cd \$WORKSPACE/srcdir/
mkdir -p \$prefix/share
cp $amazon_root_certificate_filename \$prefix/share/$amazon_root_certificate_filename
cp $rds_root_certificate_filename \$prefix/share/$rds_root_certificate_filename
cat $rds_root_certificate_filename $amazon_root_certificate_filename > \$prefix/share/$combined_root_certificates_filename
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("share/$amazon_root_certificate_filename", :amazon_ca_root_certificate),
    FileProduct("share/$rds_root_certificate_filename", :rds_ca_root_certificate),
    FileProduct("share/$combined_root_certificates_filename", :combined_ca_root_certificates),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, tarball_version, sources, script, platforms, products, dependencies)
