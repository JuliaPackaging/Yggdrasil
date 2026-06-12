# To ensure a build, it isn't sufficient to modify osqp_common.jl.
# You also need to update a line in this file:
#     Last updated: 2025-05-29

include("../osqp_common.jl")

# Generate the script to build the library with double precision
dscript = build_script(algebra  = "builtin",
                       suffix   = "builtin_double",
                       usefloat = false,
                       builddir = "build-double")

# Generate the script to build the library with single precision
sscript = build_script(algebra  = "builtin",
                       suffix   = "builtin_single",
                       usefloat = true,
                       builddir = "build-single")

script = init_env_script() * dscript * sscript

# The products that we will ensure are always built
products = [
    FileProduct("share/osqp/codegen_files",  :codegen_files_dir)
    LibraryProduct("libosqp_builtin_single", :osqp_builtin_single)
    LibraryProduct("libosqp_builtin_double", :osqp_builtin_double)
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Build the package
build_tarballs(ARGS, "OSQP", version, sources, script, platforms,
               products, common_deps; julia_compat = "1.6")
