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

mkdir -p "${bindir}"

# install single thread with SSE instructions 
cc -O3 -finline-functions -funroll-loops -Wall -o "${bindir}/fasttree${exeext}" FastTree*.c -lm

# install single thread no SSE
cc -DNO_SSE -O3 -finline-functions -funroll-loops -Wall -o "${bindir}/fasttree_noSSE${exeext}" FastTree*.c -lm

# install multithread with SSE
cc -DOPENMP -fopenmp -O3 -finline-functions -funroll-loops -Wall -o "${bindir}/fasttreeMP${exeext}" FastTree*.c -lm

# install multithread no SSE
cc -DNO_SSE -fopenmp -O3 -finline-functions -funroll-loops -Wall -o "${bindir}/fasttreeMP_noSSE${exeext}" FastTree*.c -lm

# install single thread with SSE instructions and double precision
cc -DUSE_DOUBLE -O3 -finline-functions -funroll-loops -Wall -o "${bindir}/fasttree_double${exeext}" FastTree*.c -lm

# install single thread no SSE and double precision
cc -DUSE_DOUBLE -DNO_SSE -O3 -finline-functions -funroll-loops -Wall -o "${bindir}/fasttree_double_noSSE${exeext}" FastTree*.c -lm

# install multithread with SSE and double precision
cc -DUSE_DOUBLE -DOPENMP -fopenmp -O3 -finline-functions -funroll-loops -Wall -o "${bindir}/fasttreeMP_double${exeext}" FastTree*.c -lm

# install multithread no SSE and double precision
cc -DUSE_DOUBLE -DNO_SSE -fopenmp -O3 -finline-functions -funroll-loops -Wall -o "${bindir}/fasttreeMP_double_noSSE${exeext}" FastTree*.c -lm

"""

platforms = supported_platforms()

products = [
    ExecutableProduct("fasttree", :fasttree),
    ExecutableProduct("fasttree_noSSE", :fasttree_noSSE),
    ExecutableProduct("fasttreeMP", :fasttreeMP),
    ExecutableProduct("fasttreeMP_noSSE", :fasttreeMP_noSSE),
    ExecutableProduct("fasttree_double", :fasttree_double),
    ExecutableProduct("fasttree_double_noSSE", :fasttree_double_noSSE),
    ExecutableProduct("fasttreeMP_double", :fasttreeMP_double),
    ExecutableProduct("fasttreeMP_double_noSSE", :fasttreeMP_double_noSSE),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
