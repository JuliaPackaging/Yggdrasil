const ROCM_GIT = "https://github.com/RadeonOpenCompute/llvm-project.git"
const ROCM_TAGS = Dict(
    v"4.2.0" => "b204d7f0cae65b6cd4446eec50fc1fb675d582af",
    v"4.5.2" => "9bbd96fd1936641cd47defd8022edafd063019d5",
    v"5.2.3" => "575c504b18f2f7e06fa77a3d2f63c83ed930053a",
    v"5.4.4" => "f3d695fc2985a8dfdd5f4219d351fdeac3038867",
)
const LLVM_VERSIONS = Dict(
    v"4.2.0" => v"12.0.0",
    v"4.5.2" => v"13.0.0",
    v"5.2.3" => v"14.0.0",
    v"5.4.4" => v"15.0.0",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

function configure_build(rocm_version; assert::Bool = false)
    isfile("../buildscript.sh") || error("Cannot find `./buildscript.sh`!")
    buildscript = read("../buildscript.sh", String)

    git_version = ROCM_TAGS[rocm_version]
    llvm_version = LLVM_VERSIONS[rocm_version]

    sources = [
        GitSource(ROCM_GIT, git_version),
        DirectorySource("./bundled"),
    ]

    llib = "llvm/lib"
    lbin = "llvm/bin"
    products = [
        FileProduct(joinpath(llib, "libLLVMCore.a"), :libllvmcore),
        FileProduct(joinpath(llib, "libclangBasic.a"), :libclangbasic),
        LibraryProduct("libclang", :libclang, llib; dont_dlopen=true),
        LibraryProduct("libclang-cpp", :libclang_cpp, llib; dont_dlopen=true),
        LibraryProduct(["LTO", "libLTO"], :liblto, llib; dont_dlopen=true),
        ExecutableProduct("llvm-config", :llvm_config, lbin),
        ExecutableProduct(["clang", "clang-$(llvm_version.major)"], :clang, lbin),
        ExecutableProduct("opt", :opt, lbin),
        ExecutableProduct("llc", :llc, lbin),
        ExecutableProduct("lld", :lld, lbin),
        ExecutableProduct("ld.lld", :ld_lld, lbin),
    ]

    name = "ROCmLLVM"
    config = "LLVM_MAJ_VER=$(llvm_version.major)\nLLVM_MIN_VER=$(llvm_version.minor)\nLLVM_PATCH_VER=$(llvm_version.patch)\n"
    assert && (config *= "ASSERTS=1\n";)

    dependencies = [Dependency("Zlib_jll")]
    buildscript = config * buildscript
    (
        name, rocm_version, sources,
        buildscript, ROCM_PLATFORMS, products, dependencies)
end
