using BinaryBuilder, Pkg

name = "FastANI"
version = v"1.33.0"
sources = [
    GitSource("https://github.com/ParBLiSS/FastANI.git", "6531da0957344d2a56e3eeb9bb83fea02cc4abe0"),
]


script = raw"""
cd ${WORKSPACE}/srcdir/FastANI
mkdir -p "${bindir}"
c++ -O3 -DNDEBUG -std=c++11 -Isrc -fopenmp   src/cgi/core_genome_identity.cpp -o "${bindir}/fastANI${exeext}" -lgsl -lgslcblas -lz -lm  
"""


platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("fastANI", :fastANI),
]

dependencies = [
    # Dependency(PackageSpec(name="Boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75")),
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
