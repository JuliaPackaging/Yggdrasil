using BinaryBuilder, Pkg

name = "FastTree"
version = v"2.1.11"
hash = "9026ae550307374be92913d3098f8d44187d30bea07902b9dcbfb123eaa2050f"
sources = [
    FileSource("http://www.microbesonline.org/fasttree/FastTree-$(version).c", hash),
]

script = raw"""
cd ${WORKSPACE}/srcdir/

head -42 FastTree*.c > LICENSE

# install single thread with SSE instructions 
gcc -O3 -finline-functions -funroll-loops -Wall -o FastTree FastTree*.c -lm
install -Dvm 755 "FastTree" "${bindir}/fasttree${exeext}"

# install single thread no SSE
gcc -DNO_SSE -O3 -finline-functions -funroll-loops -Wall -o FastTree_noSSE FastTree*.c -lm
install -Dvm 755 "FastTree_noSSE" "${bindir}/fasttree_noSSE${exeext}"

# install multithread with SSE
gcc -DOPENMP -fopenmp -O3 -finline-functions -funroll-loops -Wall -o FastTreeMP FastTree*.c -lm
install -Dvm 755 "FastTreeMP" "${bindir}/fasttreeMP${exeext}"

# install multithread no SSE
gcc -DNO_SSE -fopenmp -O3 -finline-functions -funroll-loops -Wall -o FastTreeMP_noSSE FastTree*.c -lm
install -Dvm 755 "FastTreeMP_noSSE" "${bindir}/fasttreeMP_noSSE${exeext}"

"""

platforms = supported_platforms()

products = [
    ExecutableProduct("fasttree", :fasttree),
    ExecutableProduct("fasttree_noSSE", :fasttree_noSSE),
    ExecutableProduct("fasttreeMP", :fasttreeMP),
    ExecutableProduct("fasttreeMP_noSSE", :fasttreeMP_noSSE),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")