# Build rootfs
#./build_rootfs.sh

BB_PATH=$(julia -e 'using BinaryBuilder; print(abspath(dirname(dirname(pathof(BinaryBuilder)))))')

# Copy everything over to ~/.julia/dev/BinaryBuilder/deps/downloads
for proj in Rootfs BaseCompilerShard GCC LLVM; do
    rsync -Pav --exclude='*.jl' "${proj}/products/" "${BB_PATH}/deps/downloads"
done

# Clean out mounts
rm -rf "${BB_PATH}/deps/mounts"

# Re-generate RootfsHashTable.jl
./build_hashes.jl
