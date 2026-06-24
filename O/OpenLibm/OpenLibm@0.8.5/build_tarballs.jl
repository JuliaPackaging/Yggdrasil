using BinaryBuilder
using Pkg
using BinaryBuilderBase: sanitize

name = "OpenLibm"
version = v"0.8.5"
sources = [
    GitSource("https://github.com/JuliaMath/openlibm.git",
              "db24332879c320606c37f77fea165e6ecb49153c"),
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/openlibm*

# Install into output
flags=("prefix=${prefix}")

# Build ARCH from ${target}
flags+=("ARCH=${target%-*-*}")

# OpenLibm build system doesn't recognize our windows cross compilers properly
if [[ ${target} == *mingw* ]]; then
    flags+=("OS=WINNT")
fi

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

# Add `CC` override, since OpenLibm seems to think it knows best:
flags+=("CC=$CC")

# Build the library
make "${flags[@]}" -j${nproc}

# Install the library
make "${flags[@]}" install

install_license ./LICENSE.md
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

products = [
    LibraryProduct("libopenlibm", :libopenlibm),
]

llvm_version = v"13.0.1"
dependencies = [
    BuildDependency(PackageSpec(; name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version); platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               lock_microarchitecture=false,
               julia_compat="1.6",
               preferred_llvm_version=llvm_version,
               preferred_gcc_version=v"8")

# Build trigger: 1
