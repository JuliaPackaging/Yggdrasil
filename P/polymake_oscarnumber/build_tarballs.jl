# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")
# we only support julia >=1.10
filter!(>=(v"1.10"), julia_versions)

# reminder: change the version when changing the supported julia versions
name = "polymake_oscarnumber"
version = v"0.3.15"

# reminder: change the above version when changing the supported julia versions
# julia_versions is now taken from libjulia/common.jl and filtered
julia_compat = libjulia_julia_compat(julia_versions)

# Collection of sources required to build polymake
sources = [
    GitSource("https://github.com/benlorenz/oscarnumber",
              "4cc18a5e8f7bfacf7276155765998772ddcb4a53")
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oscarnumber

apk add perl-json

mkdir -p build/Opt
cp ../config/config.ninja build/
cp ../config/build.ninja build/Opt/
ln -s ../config.ninja build/Opt/config.ninja

# symlink tree for all dependencies, see polymake_jll
mkdir -p ${prefix}/deps
for dir in FLINT GMP MPFR PPL Perl SCIP bliss boost cddlib lrslib normaliz; do
   ln -s .. ${prefix}/deps/${dir}_jll
done

unset LD_LIBRARY_PATH
perl ${prefix}/share/polymake/support/generate_ninja_targets.pl build/targets.ninja ${prefix}/share/polymake build/config.ninja

ninja -v -C build/Opt -j${nproc}

ninja -v -C build/Opt install

conf=${libdir}/polymake/ext/oscarnumber/config.ninja
# make prefix a variable in installed config
sed -i -e "s#${prefix}#\${prefix}#g" ${conf}
# linking to julia is not required for runtime wrappers
sed -i -e "s#-ljulia##g" ${conf}

# remove no-openmp flag (apple compilers don't support that flag)
if [[ $target == *apple* ]]; then
   sed -i -e "s#-fno-openmp##g" ${conf}
fi

# cleanup symlink tree
rm -rf ${prefix}/deps

install_license LICENSE
"""

platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!(p -> !Sys.iswindows(p) && arch(p) != "armv6l", platforms)
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> arch(p) != "riscv64", platforms) # filter riscv64 until supported by all dependencies
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpolymake_oscarnumber", :libpolymake_oscarnumber, ["lib/polymake/lib"])
]


# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),

    BuildDependency(PackageSpec(;name="libjulia_jll", version="1.11.0")),

    Dependency("libcxxwrap_julia_jll"; compat = "~0.14.9"),
    Dependency("libpolymake_julia_jll", compat = "=0.14.5"),
    Dependency("polymake_jll", compat = "~400.1500.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat=julia_compat,
               preferred_gcc_version=v"8")
