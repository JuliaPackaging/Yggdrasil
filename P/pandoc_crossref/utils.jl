# pandoc-crossref appears to be using the Haskell Package Versioning Policy. The forth
# component of the version number is maintainer specified and for pandoc-crossref is always
# a digit followed by an optional letter.
#
# https://pvp.haskell.org/
# https://github.com/lierdakil/pandoc-crossref/releases
function pandoc_crossref_jll_version(v::AbstractString)
    version_regex = r"""^(?<major1>\d+) # outer major version is one or more digits
                        \.(?<major2>\d{1,2}) # inner major version is one or two digits
                        \.(?<minor>\d+) # minor version is one or more digits
                        (\.(?<patch>\d))? # patch version is one or more digits and optional
                        (?<build>[a-z])?$ # build is one or more letters and optional
                        """x
    m = match(version_regex, v)
    if !isnothing(m)
        if !isnothing(m[:build])
            build_letter = only(collect(m[:build]))
            build_num = build_letter - 'a' + 1
        else
            build_num = 0
        end

        patch = something(m[:patch], "0")
        # Note: Version 0.3.16.0a occurs after 0.3.16.0
        return VersionNumber(
            parse(Int, m[:major1]) * 100 + parse(Int, m[:major2]),
            parse(Int, m[:minor]),
            parse(Int, patch) * 100 + build_num,
        )
    else
        throw(ArgumentError("Unhandled pandoc-crossref version number: $v"))
    end
end
