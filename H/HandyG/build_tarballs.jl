using BinaryBuilder

name = "HandyG"
# Upstream tag is `v0.2.0b` (beta), but BinaryBuilder requires `major.minor.patch`.
version = v"0.2.0"

sources = [
    GitSource("https://gitlab.com/mule-tools/handyG.git",
              "756ab007b4655e0b37244dd0dcc072f3ae7f4bc8"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/handyG*

# Add stable C-ABI entrypoints used by HandyG.jl
cp ${WORKSPACE}/srcdir/handyg_capi.f90 src/

mkdir -p build

# Some platforms (e.g. i686, armv6l/armv7l) do not support INTEGER(16).
# handyG uses it in `utils.f90` for `binom()`, but 64-bit is sufficient here.
sed -i 's/integer(16) :: num, den/integer(kind=selected_int_kind(18)) :: num, den/' src/utils.f90

# handyG ships a configure-based build system, but it is not designed for cross-compiling.
# Here we compile the minimal set of Fortran sources directly into a shared library.
FFLAGS="-cpp -O3"
if [[ "${target}" != *mingw* ]]; then
  FFLAGS="${FFLAGS} -fPIC"
fi

for f in globals ieps utils shuffle maths_functions mpl_module gpl_module handyg_capi; do
  gfortran ${FFLAGS} -J build -I build -c src/${f}.f90 -o build/${f}.o
done

if [[ "${target}" == *apple* ]]; then
  gfortran -dynamiclib -o libhandyg.${dlext} build/*.o
else
  gfortran -shared -o libhandyg.${dlext} build/*.o
fi

install -Dvm 755 libhandyg.${dlext} ${libdir}/libhandyg.${dlext}

install_license LICENSE
"""

platforms = expand_gfortran_versions(supported_platforms())

products = [
    LibraryProduct("libhandyg", :libhandyg),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
