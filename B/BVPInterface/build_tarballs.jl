using BinaryBuilder

name = "BVPInterface"
version = v"0.0.1"

function get_autogenerated_build_script()
  return raw"""
    cd $WORKSPACE/srcdir/BVPInterfac*/src

    # lapack
    ${FC} -c -fPIC -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./dc_lapack.o ./dc_lapack.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./dc_lapack_i32.o ./dc_lapack.f
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./lapack.o ./lapack.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./lapack_i32.o ./lapack.f
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./lapackc.o ./lapackc.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./lapackc_i32.o ./lapackc.f

    # slatec
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./slatec.o ./slatec.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./slatec_i32.o ./slatec.f

    # bvpsol
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./bvpsol.o ./bvpsol.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./bvpsol_i32.o ./bvpsol.f
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./linalg_bvpsol.o ./linalg_bvpsol.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./linalg_bvpsol_i32.o ./linalg_bvpsol.f
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./zibconst.o ./zibconst.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./zibconst_i32.o ./zibconst.f
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./ma28_bvpsol.o ./ma28_bvpsol.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./ma28_bvpsol_i32.o ./ma28_bvpsol.f
    ${FC} -shared -fPIC -o ./bvpsol.${dlext} ./bvpsol.o ./linalg_bvpsol.o ./zibconst.o ./ma28_bvpsol.o
    ${FC} -shared -fPIC -o ./bvpsol_i32.${dlext} ./bvpsol_i32.o ./linalg_bvpsol_i32.o ./zibconst_i32.o ./ma28_bvpsol_i32.o
    
    # colnew
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./colnew.o ./colnew.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./colnew_i32.o ./colnew.f
    ${FC} -shared -fPIC -o ./colnew.${dlext} ./colnew.o
    ${FC} -shared -fPIC -o ./colnew_i32.${dlext} ./colnew_i32.o

    # coldae
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./coldae.o ./coldae.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./coldae_i32.o ./coldae.f
    ${FC} -shared -fPIC -o ./coldae.${dlext} ./coldae.o
    ${FC} -shared -fPIC -o ./coldae_i32.${dlext} ./coldae_i32.o

    # colmod
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./colmod.o ./colmod.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./colmod_i32.o ./colmod.f
    ${FC} -shared -fPIC -o ./colmod.${dlext} ./colmod.o
    ${FC} -shared -fPIC -o ./colmod_i32.${dlext} ./colmod_i32.o

    # colsys
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./colsys.o ./colsys.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./colsys_i32.o ./colsys.f
    ${FC} -shared -fPIC -o ./colsys.${dlext} ./colsys.o
    ${FC} -shared -fPIC -o ./colsys_i32.${dlext} ./colsys_i32.o

    # twpbvp
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./twpbvp.o ./twpbvp.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./twpbvp_i32.o ./twpbvp.f
    ${FC} -shared -fPIC -o ./twpbvp.${dlext} ./twpbvp.o
    ${FC} -shared -fPIC -o ./twpbvp_i32.${dlext} ./twpbvp_i32.o 
    
    # bvpm2
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./bvp_la-2.o ./bvp_la-2.f
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -std=f2008 -o ./bvp_m-2.o ./bvp_m-2.f90
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -Wall -Wextra -Wimplicit-interface -std=f2008ts -o ./bvp_m_proxy.o ./bvp_m_proxy.f90
    ${FC} -shared -fPIC -o ./bvp_m_proxy.${dlext} ./bvp_m_proxy.o ./bvp_m-2.o ./bvp_la-2.o

    # musl
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./musl.o ./musl.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./musl.o ./musl.f
    ${FC} -shared -fPIC -o ./musl.${dlext} ./musl.o
    ${FC} -shared -fPIC -o ./musl.${dlext} ./musl.o

    # musn
    ${FC} -c -fPIC -fdefault-integer-8 -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./musn.o ./musn.f
    ${FC} -c -fPIC -fdefault-real-8 -fdefault-double-8 -w -std=legacy -o ./musn.o ./musn.f
    ${FC} -shared -fPIC -o ./musn.${dlext} ./musn.o
    ${FC} -shared -fPIC -o ./musn.${dlext} ./musn.o

    install -Dvm 755 *.${dlext} $libdir
  """
end

sources = [
  GitSource("https://github.com/ErikQQY/BVPInterface.jl", "1ceb9195c2c9335a7cf1c10d774b8f4d84c35d1f"),
]

script = get_autogenerated_build_script()

platforms = expand_gfortran_versions(supported_platforms())

products = [
  LibraryProduct("bvpsol",       :libbvpsol),
  LibraryProduct("bvpsol_i32",   :libbvpsol_i32),
  LibraryProduct("colnew",       :libcolnew),
  LibraryProduct("colnew_i32",   :libcolnew_i32),
  LibraryProduct("coldae",       :libcoldae),
  LibraryProduct("coldae_i32",   :libcoldae_i32),
  LibraryProduct("colsys",       :libcolsys),
  LibraryProduct("colsys_i32",   :libcolsys_i32),
  LibraryProduct("colmod",       :libcolmod),
  LibraryProduct("colmod_i32",   :libcolmod_i32),
  LibraryProduct("twpbvp",       :libtwpbvp),
  LibraryProduct("twpbvp_i32",   :libtwpbvp_i32),
  LibraryProduct("musl",         :libmusl),
  LibraryProduct("musl_i32",     :libmusl_i32),
  LibraryProduct("musn",         :libmusn),
  LibraryProduct("musn_i32",     :libmusn_i32),
  LibraryProduct("bvp_m_proxy",  :libbvp_m_proxy),
]

dependencies = [
  Dependency("CompilerSupportLibraries_jll")
]

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9.1.0")
