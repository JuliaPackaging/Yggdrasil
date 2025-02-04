using BinaryBuilder, Pkg

uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "libblocksqp"
version = v"0.0.1"
sources = [
    GitSource("https://github.com/djanka2/blockSQP.git", "da05d3957b93bd55b9a7f08c859d302851056a6d"),
    DirectorySource("./bundled")
]


include("../../L/libjulia/common.jl")

# This is for anyone who is on macos
preamble = if os() === "macos"
    raw"cd /usr/share/cmake/Modules/Compiler/; find  . -name '._*' -exec rm {} \;"
else
    raw""
end


script = preamble * raw"
cd ${WORKSPACE}/srcdir
mv CMakeLists.txt blockSQP/CMakeLists.txt
mv blockSQP_julia.cpp blockSQP/src/blockSQP_julia.cpp
cd blockSQP
mkdir build && cd build

BLASLIBNAME=\"libblastrampoline\"
if [ ! -f ${libdir}/${BLASLIBNAME}.${dlext} ]; then
    echo \"${libdir}/${BLASLIBNAME}.${dlext} not found.\"
    if [[ \"${target}\" == *-mingw* ]]; then
        BLASLIBNAME=\"libblastrampoline-5\"
    fi
fi


if [[ \"${nbits}\" == 64 ]]; then

    SYMB_DEFS=()
    if [[ \"${target}\" != *-apple-* ]]; then
        for sym in cblas_dgemm; do
            SYMB_DEFS+=(\"-D${sym}=${sym}64_\")
        done
    fi
    if [[ \"${target}\" == *-apple-* ]] || [[ \"${target}\" == *-mingw* ]]; then
        FLAGS+=(-DALLOW_OPENBLAS_MACOS=ON)
    fi


    export CXXFLAGS=\"${SYMB_DEFS[@]}\"

fi

cmake \
    -DJulia_PREFIX=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_PREFIX_PATH=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DLAPACK_LIBRARIES=${libdir}/${BLASLIBNAME}.${dlext}\
    -DBLAS_LIBRARIES=${libdir}/${BLASLIBNAME}.${dlext} \
    ..

make
make install
install_license ${WORKSPACE}/srcdir/blockSQP/LICENSE
"

#platforms = vcat(libjulia_platforms.(julia_versions[julia_versions .>= v"1.7.0"])...) |> expand_cxxstring_abis
platforms = vcat(libjulia_platforms.(julia_versions)...) |> expand_cxxstring_abis
filter!(p -> !(arch(p) == "i686"), platforms)
filter!(p -> !(libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
filter!(p -> !(os(p) == "freebsd"), platforms)



dependencies = [
    Dependency("qpOASES_jll"),
    Dependency("libblastrampoline_jll"),#; compat="5.4.0"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency("libjulia_jll")
]

products = [
    LibraryProduct("libblockSQP", :libblockSQP)
    LibraryProduct("libblockSQP_wrapper", :libblockSQP_wrapper)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
        julia_compat="1.7", preferred_gcc_version=v"9")
