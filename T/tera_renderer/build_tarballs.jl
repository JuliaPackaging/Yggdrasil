# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tera_renderer"
version = v"0.2.1"

# `t_renderer` is the Tera template renderer acados uses to generate its C solvers from JSON
# problem descriptions (https://docs.acados.org). The repository ships no license file; the tool is
# developed by the acados authors and distributed with acados, so the acados license (2-clause BSD)
# is installed alongside.
sources = [
    GitSource("https://github.com/acados/tera_renderer.git", "a480a64b0a2cc15d4b1e6146e986388709ac0716"),   # v0.2.1
    FileSource("https://raw.githubusercontent.com/acados/acados/503364817c872d474ab5bed219c26760ac267769/LICENSE",
               "43c978e77d8d3721cbd701539724b3460e68f9d0dddfad76902237dc706f7fcc"; filename = "LICENSE"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/tera_renderer
cargo build --release
install -Dvm 755 "target/${rust_target}/release/t_renderer${exeext}" "${bindir}/t_renderer${exeext}"
install_license ${WORKSPACE}/srcdir/LICENSE
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

products = [
    ExecutableProduct("t_renderer", :t_renderer),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers = [:c, :rust], julia_compat = "1.6")
