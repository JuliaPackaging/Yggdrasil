# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "PlantUML"
version = v"1.2025.2"

# Collection of sources required to build Git
sources = [
    FileSource("https://github.com/plantuml/plantuml/releases/download/v$(version)/plantuml-$(version).jar",
        "862c7d6d0d3bde3c819eac4dfc03cf549046bf1d49c04d18a779eb2d834b77c9"),
    FileSource("https://www.gnu.org/licenses/gpl-3.0.en.html",
        "e5266b651fc22c05c23a4f249c356117063d58029b289eff85c25eb03ee0e7d0"),
]

# Bash recipe for building across all platforms
script = """
cd \${WORKSPACE}
install_license srcdir/gpl-3.0.en.html

cp srcdir/plantuml-$(version).jar \${prefix}/plantuml.jar
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    FileProduct("plantuml.jar", :plantuml),
]

# Dependencies that must be installed before this package can be built
dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
