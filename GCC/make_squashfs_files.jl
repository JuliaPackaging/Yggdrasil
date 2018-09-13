#!/usr/bin/env julia

using BinaryBuilder, SHA

for f in readdir("products/")
    if !endswith(f, ".tar.gz")
        continue
    end

    tarball_path = joinpath("products", f)
    squash_path = joinpath("products", f[1:end-7]*".squashfs")

    # If the squash file is newer than the tarball, SKIPIT
    if isfile(squash_path) && mtime(squash_path) > mtime(tarball_path)
        continue
    end

    temp_prefix() do p
        @info("Extracting $f....")
        unpack(tarball_path, p.path)

        @info("Squashing $f....")
        run(`mksquashfs $(p.path) $(squash_path) -force-uid 0 -force-gid 0 -comp xz -b 1048576 -Xdict-size 100% -noappend`)
        
        @info("Hashing $f....")
        # Hash it to get the .sha256 file:
        squash_hash = open(squash_path, "r") do f
            bytes2hex(sha256(f))
        end
        open(squash_path * ".sha256", "w") do f
            write(f, squash_hash)
        end
    end
end

