# Flow*: A verification tool for cyber-physical systems
# see: https://flowstar.org/examples/

# LICENSE from https://flowstar.org/dowloads/ stating:
# "The source code is released under the [GNU General Public License (GPL)](https://www.gnu.org/licenses/gpl-3.0.html). We are happy to release the code under a license that is more (or less) permissive upon request."

using BinaryBuilder

platforms = supported_platforms(exclude=Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)

name = "Flowstar"
version = v"2.1.0"
sources = [
    ArchiveSource("https://www.cs.colorado.edu/~xich8622/src/flowstar-$version.tar.gz", "642b17a55c6725d4bfc5b98900802e3b82f37fbbe9fb9028f1110c669a5afc86")
    FileSource("https://www.gnu.org/licenses/gpl-3.0.txt", "3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986"; filename = "LICENSE")
]

begin
    script = raw"""
    cd ${WORKSPACE}/srcdir/flowstar-VERSION
    make -j${nproc}
    chmod +x flowstar
    cp flowstar ${bindir}
    """
    script = replace(script,"VERSION"=>"$version")
end

products = [
    ExecutableProduct("flowstar", :flowstar)
]

dependencies = [
    HostBuildDependency("flex_jll"),
    HostBuildDependency("Bison_jll"),
    Dependency("MPFR_jll"),
    Dependency("GSL_jll"),
    Dependency("GLPK_jll"),
    Dependency("GMP_jll")
]

res = build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
        julia_compat = "1.6", preferred_gcc_version=v"8")