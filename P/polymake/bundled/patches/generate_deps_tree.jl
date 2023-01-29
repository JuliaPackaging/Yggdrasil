using Pkg.Artifacts
import Pkg
import polymake_jll

# adapted from https://github.com/JuliaLang/julia/pull/38797
function full_artifact_dir(m::Module)
   artifacts_toml = joinpath(dirname(dirname(Base.pathof(m))), "StdlibArtifacts.toml")

   # If this file exists, it's a stdlib JLL and we must download the artifact ourselves
   if isfile(artifacts_toml)
       # we need to remove the _jll for the artifact name
       meta = artifact_meta(string(m)[1:end-4], artifacts_toml)
       hash = Base.SHA1(meta["git-tree-sha1"])
       if !artifact_exists(hash)
           dl_info = first(meta["download"])
           download_artifact(hash, dl_info["url"], dl_info["sha256"])
           # to make sure stdlib artifacts are preserved
           # https://github.com/JuliaLang/Pkg.jl/issues/2874
           Pkg.Types.write_env_usage(artifacts_toml, "artifact_usage.toml")
       end
       return artifact_path(hash)
   else
      # Otherwise, we can just use the artifact directory given to us by the module
      return m.artifact_dir
   end
end

function force_symlink(source::AbstractString, target::AbstractString)
   tmpfile = tempname(dirname(target); cleanup=false)
   symlink(source, tmpfile)
   Base.Filesystem.rename(tmpfile, target)
end

function prepare_deps_tree(targetdir::String)
   # create a directory tree for polymake with links to dependencies
   # looking similiar to the tree in the build environment
   # for compiling wrappers at run-time
   mkpath(joinpath(targetdir,"deps"))
   deps = [ polymake_jll.FLINT_jll,
            polymake_jll.GMP_jll,
            polymake_jll.MPFR_jll,
            polymake_jll.PPL_jll,
            polymake_jll.Perl_jll,
            polymake_jll.SCIP_jll,
            polymake_jll.bliss_jll,
            polymake_jll.boost_jll,
            polymake_jll.cddlib_jll,
            polymake_jll.lrslib_jll,
            polymake_jll.normaliz_jll ]

   # dependencies
   for dep in deps
      target = joinpath(targetdir,"deps","$dep")
      force_symlink(full_artifact_dir(dep), target)
   end

   # polymake prefix directories
   for dir in filter(d -> d!="bin", readdir(polymake_jll.artifact_dir))
      target = joinpath(targetdir,dir)
      force_symlink(joinpath(polymake_jll.artifact_dir,dir), target)
   end

   # polymake perl scripts
   bindir(name) = joinpath(targetdir,"bin", name)
   mkpath(bindir(""))
   for file in ("polymake", "polymake-config")
      force_symlink(joinpath(polymake_jll.artifact_dir, "bin", file), bindir(file))
   end

   # Point polymake to our custom tree
   return targetdir
end
