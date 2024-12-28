# pandoc-crossref appears to be using the Haskell Package Versioning Policy. The forth
# component of the version number is maintainer specified and for pandoc-crossref is always
# a digit followed by an optional letter.
#
# https://pvp.haskell.org/
# https://github.com/lierdakil/pandoc-crossref/releases
function pandoc_crossref_jll_version(v::AbstractString)
    m = match(r"^(?<major1>\d+)\.(?<major2>\d{1,2})\.(?<minor>\d+)\.(?<patch>\d)(?<build>[a-z])?$", v)
    if !isnothing(m)
        if !isnothing(m[:build])
            build_letter = only(collect(m[:build]))
            build_num = build_letter - 'a' + 1
        else
            build_num = 0
        end

        # Note: Version 0.3.16.0a occurs after 0.3.16.0
        return VersionNumber(
            parse(Int, m[:major1]) * 100 + parse(Int, m[:major2]),
            parse(Int, m[:minor]),
            parse(Int, m[:patch]) * 100 + build_num,
        )
    else
        throw(ArgumentError("Unhandled pandoc-crossref version number: $v"))
    end
end
