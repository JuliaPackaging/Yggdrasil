using BinaryBuilder

name = "HandyG"
# Upstream tag is `v0.2.0b` (beta), but BinaryBuilder requires `major.minor.patch`.
version = v"0.2.0"

sources = [
    GitSource("https://gitlab.com/mule-tools/handyG.git",
              "756ab007b4655e0b37244dd0dcc072f3ae7f4bc8"; unpack_target="handyg"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/handyg
# GitSource may introduce an extra directory level; locate the actual source root.
if [[ ! -d src ]]; then
  for d in ${WORKSPACE}/srcdir/handyg/*; do
    if [[ -d "${d}/src" ]]; then
      cd "${d}"
      break
    fi
  done
fi
if [[ ! -d src ]]; then
  echo "ERROR: Could not find handyG source directory (expected src/)."
  echo "PWD=$(pwd)"
  ls -la
  exit 1
fi

# Add stable C-ABI entrypoints used by HandyG.jl
cp ${WORKSPACE}/srcdir/bundled/handyg_capi.f90 src/handyg_capi.f90

mkdir -p build

# Some platforms (e.g. i686, armv6l/armv7l) do not support INTEGER(16).
# handyG uses it in `utils.f90` for `binom()`, but 64-bit is sufficient here.
sed -i 's/integer(16) :: num, den/integer(kind=selected_int_kind(18)) :: num, den/' src/utils.f90

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
if [[ "${target}" == *mingw* ]]; then
  install -Dvm 755 libhandyg.${dlext} ${bindir}/libhandyg.${dlext}
fi

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
