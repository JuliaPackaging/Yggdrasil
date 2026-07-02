using BinaryBuilder

name = "ovstorage"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/NVIDIA-Omniverse/ovstorage.git", "766a1c55ca95c723c73f0381f759ace8cd479e99"),
]

# Bundles libovstorage plus every first-party plugin, mirroring upstream's
# own `xtask dist` (see PLUGINS/LIBRARIES in xtask/src/dist.rs).
script = raw"""
cd ${WORKSPACE}/srcdir/ovstorage*/

mkdir -p "${libdir}/plugins" "${includedir}"

# The sandbox's /tmp is a small tmpfs; cc scratch files (ring, sqlite3)
# fill it fast across 6 heavy workspaces. Redirect to workspace disk.
mkdir -p "${WORKSPACE}/tmpdir"
export TMPDIR="${WORKSPACE}/tmpdir"

# build.rs nested-builds a test plugin without --target, breaking cross
# builds; this upstream-provided override skips it.
export OVSTORAGE_EXAMPLE_PLUGIN_RUST_SO_OVERRIDE=/dev/null

# Each workspace's target/ is deleted after its artifacts are copied,
# capping disk to one workspace's build output at a time.
(cd ovstorage-core && cargo build --release --locked \
    -p ovstorage-capi -p ovstorage-plugin-file -p ovstorage-plugin-http -p ovstorage-plugin-test)
install -Dvm755 ovstorage-core/target/${rust_target}/release/*ovstorage.${dlext} -t "${libdir}"
for plugin in ovstorage_plugin_file ovstorage_plugin_http ovstorage_plugin_test; do
    install -Dvm755 ovstorage-core/target/${rust_target}/release/*${plugin}.${dlext} -t "${libdir}/plugins"
done
install -Dvm644 ovstorage-core/crates/ovstorage-capi/include/ovstorage.h "${includedir}/ovstorage.h"
install -Dvm644 ovstorage-core/crates/ovstorage-capi/include/ovstorage.hpp "${includedir}/ovstorage.hpp"
rm -rf ovstorage-core/target

(cd ovstorage-cloud && cargo build --release --locked \
    -p ovstorage-plugin-s3 -p ovstorage-plugin-gcs -p ovstorage-plugin-azure -p ovstorage-plugin-opendal)
for plugin in ovstorage_plugin_s3 ovstorage_plugin_gcs ovstorage_plugin_azure ovstorage_plugin_opendal; do
    install -Dvm755 ovstorage-cloud/target/${rust_target}/release/*${plugin}.${dlext} -t "${libdir}/plugins"
done
rm -rf ovstorage-cloud/target

(cd ovstorage-nucleus && cargo build --release --locked -p ovstorage-plugin-nucleus)
install -Dvm755 ovstorage-nucleus/target/${rust_target}/release/*ovstorage_plugin_nucleus.${dlext} -t "${libdir}/plugins"
rm -rf ovstorage-nucleus/target

(cd ovstorage-remote && cargo build --release --locked -p ovstorage-plugin-broker)
install -Dvm755 ovstorage-remote/target/${rust_target}/release/*ovstorage_plugin_broker.${dlext} -t "${libdir}/plugins"
rm -rf ovstorage-remote/target

(cd ovstorage-services-client && cargo build --release --locked -p ovstorage-plugin-services-client)
install -Dvm755 ovstorage-services-client/target/${rust_target}/release/*ovstorage_plugin_services_client.${dlext} -t "${libdir}/plugins"
rm -rf ovstorage-services-client/target

install_license LICENSE
"""

platforms = supported_platforms()

# cdylib on musl is unreliable, riscv64 has no Rust shard here, and this
# i686-windows target combination is a known-broken Rust cross target.
filter!(p -> libc(p) != "musl", platforms)
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> p != Platform("i686", "windows"), platforms)

products = [
    # Rust's cdylib output has no "lib" prefix on Windows (ovstorage.dll).
    LibraryProduct(["libovstorage", "ovstorage"], :libovstorage),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.10")
