include("common.jl")

jllversion=v"1.11.1"
for ver in julia_full_versions
    build_julia(ARGS, ver; jllversion)
end
