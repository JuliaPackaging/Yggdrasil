using BinaryBuilder2


# 1. Define package metadata and workspace
name = "WiringPi"
version = v"3.2.0"
workspace = "./build_workspace"

# 2. Declare external sources 
sources = [
    GitSource("https://github.com/WiringPi/WiringPi.git", "31f49ecdf7865c10483a91994aa51f73a7c656aa"),
    DirectorySource("./bundled")
]

# 3. Explicit target platform(s) definition
targets = [
    Platform("aarch64", "linux"; libc = "glibc")
]

# 4. Map the expected compilation output artifacts
products = [
    LibraryProduct("libwiringPi", :wiringPi)
]

# 5. Define package dependencies (none required for this build)
dependencies = BuildDependency[]

# 6. The sandbox compilation recipe
script = raw"""
cd ${WORKSPACE}/srcdir

# Apply patches from bundled directory if any exist
if [ -d "${WORKSPACE}/srcdir/patches" ]; then
    for f in ${WORKSPACE}/srcdir/patches/*.patch; do
        patch -p1 < "${f}"
    done
fi

cd WiringPi/wiringPi

# Execute build with cross-compilation environment variables automatically injected
make -j${nproc}

# Install artifacts directly into the prefix layout
make DESTDIR=${prefix} PREFIX="" LDCONFIG="" V=1 install

# Safeguard the license allocation
install_license ../COPYING.LESSER
"""

# 7. Execute the compilation jobs sequentially across target environments
for target in targets
    @info "Starting sandboxed BinaryBuilder2 build job" name version target=triplet(target)
    
    job = BuildJob(
        workspace,
        target,
        name,
        version,
        sources,
        script,
        products;
        dependencies=dependencies,
        julia_compat="1.6"
    )
    
    run_job(job)
end
