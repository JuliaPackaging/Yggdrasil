using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

if !@isdefined host_build
  host_build = false
end

platforms = host_build ? [Platform("x86_64", "linux",cxxstring_abi=:cxx11,libc="musl")] : expand_cxxstring_abis(supported_platforms())
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms) # No OpenGL on aarch64 freeBSD
filter!(p -> arch(p) != "armv6l", platforms) # No OpenGL on armv6
filter!(p -> arch(p) != "riscv64", platforms) # No OpenGL on riscv64
platforms_macos = filter(Sys.isapple, platforms)
platforms_win = filter(Sys.iswindows, platforms)
platforms = setdiff(platforms, platforms_macos, platforms_win)

# We must use the same version of LLVM for the build toolchain and LLVMCompilerRT_jll
qt_llvm_version = "16.0.6"

make_mac_product(p::Product) = p
function make_mac_product(lp::LibraryProduct)
  for pname in lp.libnames
    if startswith(pname, "Qt6")
      return FrameworkProduct("Qt"*pname[4:end], lp.variable_name)
    end
  end
  @error "No product name starting with Qt6 found in $lp"
end

function build_qt(name, version, sources, script, products, dependencies; products_win=products, ARGS=ARGS)
  products_macos = make_mac_product.(products)
  preferred_llvm_version = VersionNumber(qt_llvm_version)
  julia_compat="1.6"
  if any(should_build_platform.(triplet.(platforms_macos)))
      sources_macos, script_macos = require_macos_sdk("14.0", sources, script; deployment_target="12")
      build_tarballs(ARGS, name, version, sources_macos, script_macos, platforms_macos, products_macos, dependencies; preferred_llvm_version, julia_compat)
  end
  # GCC 12 and before fail with internal compiler error on mingw
  if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms_win, products_win, dependencies; preferred_gcc_version = v"13", preferred_llvm_version, julia_compat)
  end
  if any(should_build_platform.(triplet.(platforms)))
      build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", preferred_llvm_version, julia_compat)
  end
end
