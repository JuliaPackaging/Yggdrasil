# This is a collection of toys under the Yggdrasil tree for the good <s>kids</s>
# developers.  These utilities can be employed in builder files.

using BinaryBuilder, Pkg, LibGit2
# Note: if you only need `get_addable_spec`, just add the following line to your recipe
# instead of including this file.  This is reexported here for backward compatibility.
using BinaryBuilderBase: get_addable_spec

"""
    should_build_platform(platform) -> Bool

Return whether the tarballs for the given `platform` should be built.

This is useful when the builder has different platform-dependent elements
(sources, script, products, etc...) that make it hard to have a single
`build_tarballs` call.

Note that the platform must be augmented, e.g. wrt. CUDA, if the platform
supplied in ARGS is augmented.
"""
function should_build_platform(platform)
    # If you need inspiration for how to use this function, look at the builder
    # for Git:
    # https://github.com/JuliaPackaging/Yggdrasil/blob/c3e3c4a96c723306b4da23fc6d05f12995b21ed8/G/Git/build_tarballs.jl#L76-L93

    # Get the list of platforms requested from the command line.  This should be
    # the only argument not prefixed with "--".
    requested_platforms = filter(arg -> !occursin(r"^--.*", arg), ARGS)

    if isone(length(requested_platforms))
        # `requested_platforms` has only one element: the comma-separated list
        # of platform.  We'll run the platform only if it's in the list
        return any(platforms_match.(Ref(platform), split(requested_platforms[1], ",")))
    else
        # `requested_platforms` doesn't have only one element: if its length is
        # zero, no platform has been explicitely passed from the command line
        # and we we'll run all platforms, otherwise we don't know what to do, so
        # let's return false to be safe.
        return iszero(length(requested_platforms))
    end
end
