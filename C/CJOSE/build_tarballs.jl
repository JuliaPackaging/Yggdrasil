using BinaryBuilder, Pkg

name = "CJOSE"
# Upstream uses version numbers with 4 components in some but not all cases and it's not
# clear what each component means. For example, v0.6.2 precedes v0.6.2.1 through v0.6.2.4,
# and while some release notes include only security and/or bug fixes, v0.6.2.1 apparently
# also includes new features. So... who knows what anything means.
version = v"0.62.4"  # upstream version is 0.6.2.4

sources = [
    # NOTE: This is OpenIDC's maintenance fork, not the original Cisco repository
    GitSource("https://github.com/openidc/cjose.git",
              "8d94c3ad3237ab6a83d2e92fa541542b1b92c023")
]

script = raw"""
cd ${WORKSPACE}/srcdir/cjose
autoreconf -fiv
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libcjose", :libcjose)
]

dependencies = [
    Dependency(PackageSpec(name="Jansson_jll", uuid="83cbd138-b029-500a-bd82-26ec0fbaa0df");
               compat="2.14.1"),
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95");
               compat="3.0.16")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
