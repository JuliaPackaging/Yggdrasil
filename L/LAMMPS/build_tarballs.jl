# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

include("../../fancy_toys.jl")

name = "LAMMPS"
version = v"1.0.0" # Equivalent to 2020-10-29

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lammps/lammps.git", "88fd96ec52f86dba4b222623f3a06632a32e42f1")
]

# Bash recipe for building across all platforms
script = raw"""
cp `which c++` `which c++`.bak
cp `which cc` `which cc`.bak
export OLDCC=$(tail `which cc`.bak | grep '[^ ]*gcc' -o)
export OLDCXX=$(tail `which cc`.bak | grep '[^ ]*g++' -o)
cd $WORKSPACE/srcdir/lammps/
mkdir build && cd build/
mv ${host_prefix}/bin/lld ${host_prefix}/tools/
sed -i '$d' `which c++`
sed -i '/march=[^"]/d' `which c++`


export FLAGS="-B $(dirname `$OLDCC -print-file-name=crtbeginS.o`) --sysroot `$OLDCC -print-sysroot` -L $(dirname `$OLDCC -print-libgcc-file-name`) --gcc-toolchain=$(dirname $OLDCC) -fuse-ld=lld -I `$OLDCC -print-sysroot`/../include/c++/*/ -I `$OLDCC -print-sysroot`/../include/c++/*/x86*"
echo "vrun \${CCACHE} ${host_prefix}/tools/clang++ $FLAGS \"\${PRE_FLAGS[@]}" \"\${ARGS[@]}\" \"\${POST_FLAGS[@]}\"" >> `which c++`
sed -i '$d' `which cc`
sed -i '/march=[^"]/d' `which cc`
echo "vrun \${CCACHE} ${host_prefix}/tools/clang $FLAGS \"\${PRE_FLAGS[@]}" \"\${ARGS[@]}\" \"\${POST_FLAGS[@]}\"" >> `which cc`
cmake ../cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLAMMPS_EXCEPTIONS=ON \
    -DCMAKE_CXX_COMPILER=`which c++` \
    -DCMAKE_C_COMPILER=`which cc` \
    -DCMAKE_CXX_FLAGS="-fuse-ld=lld -flto" \
    -DPKG_SNAP=ON
make -j${nproc}
make install

if [[ "${target}" == *mingw* ]]; then
    cp *.dll ${prefix}/bin/
fi
"""

function configure(julia_version, llvm_version)
    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = expand_cxxstring_abis(supported_platforms(; experimental=false))
    filter!(p -> libc(p) != "musl" , platforms)
    filter!(p -> Sys.islinux(p), platforms)
    # filter!(p -> Sys.islinux(p) && BinaryBuilder.proc_family(p) == "intel", platforms)
    filter!(p -> arch(p) == "x86_64", platforms)
    @show platforms
    # platforms = [Pkg.BinaryPlatforms.Linux(:x86_64, libc=:glibc)]

    foreach(platforms) do p
        BinaryPlatforms.add_tag!(p.tags, "julia_version", string(julia_version))
    end

    # The products that we will ensure are always built
    products = [
        LibraryProduct("liblammps", :liblammps),
        ExecutableProduct("lmp", :lmp),
        ]

    # Dependencies that must be installed before this package can be built
    dependencies = [
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
        HostBuildDependency(get_addable_spec("LLVM_full_jll", llvm_version))
    ]

    return platforms, products, dependencies
end

# TODO: Don't require build-id on LLVM version
supported = (
    (v"1.7", v"12.0.1+4"),
)
    #(v"1.6", v"11.0.1+3"),
    #(v"1.8", v"12.0.0+0"),


for (julia_version, llvm_version) in supported
    platforms, products, dependencies = configure(julia_version, llvm_version)

    any(should_build_platform.(triplet.(platforms))) || continue

    # Build the tarballs.
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                preferred_gcc_version=v"8", julia_compat="1.6")
end
