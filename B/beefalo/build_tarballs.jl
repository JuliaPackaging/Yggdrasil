using BinaryBuilder, Pkg

# Beefalo!
name = "beefalo"
version = v"1.35.0"
beefalo_ver = "1.35.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/macd/beefalo.c.git", "d48ba216e50d7b0854bf7b6c829f04d919567411")
]

    
# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-apple-* ]]; then
    EXFLG="-D MACOS";
elif [[ "${target}" == *-w64-* ]]; then
    EXFLG="-D OSWIN";
else
    EXFLG="";
fi

cd ${WORKSPACE}/srcdir/beefalo.c
./configure  --prefix=$prefix --host=${target} --build=${MACHTYPE} CFLAGS="${CFLAGS} ${EXFLG}"
make
mkdir -p "${bindir}"
cp src/beefalo${exeext} ${bindir}
chmod +x ${bindir}/*
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("beefalo", :beefalo),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
