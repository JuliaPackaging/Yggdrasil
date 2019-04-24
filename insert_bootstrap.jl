#!/usr/bin/env julia

using SHA, BinaryProvider, BinaryBuilder
import BinaryBuilder: CompilerShard

fname = "GCCBootstrap/products/GCC-x86_64-linux-gnu.v4.8.5.x86_64-linux-gnu"
targz_hash = open("$(fname).tar.gz", "r") do f
    bytes2hex(sha256(f))
end
squashfs_hash = open("$(fname).squashfs", "r") do f
    bytes2hex(sha256(f))
end

rht_path = joinpath(dirname(pathof(BinaryBuilder)), "RootfsHashTable.jl")
include(rht_path)
shard_hash_table[CompilerShard("GCC", v"4.8.5", Linux(:x86_64), :targz; target=Linux(:x86_64))] = targz_hash
shard_hash_table[CompilerShard("GCC", v"4.8.5", Linux(:x86_64), :squashfs; target=Linux(:x86_64))] = squashfs_hash
open(rht_path, "w") do io
    write(io, repr(shard_hash_table))
end
