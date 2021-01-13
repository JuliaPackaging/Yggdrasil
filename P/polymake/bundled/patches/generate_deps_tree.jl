using Pkg.Artifacts
using polymake_jll

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
       end
       return artifact_path(hash)
   else
      # Otherwise, we can just use the artifact directory given to us by the module
      return m.artifact_dir
   end
end

function prepare_deps_tree()
   mutable_artifacts_toml = joinpath(dirname(pathof(polymake_jll)), "..", "MutableArtifacts.toml")
   polymake_tree = "polymake_tree"
   polymake_tree_hash = artifact_hash(polymake_tree, mutable_artifacts_toml)

   # create a directory tree for polymake with links to dependencies
   # looking similiar to the tree in the build environment
   # for compiling wrappers at run-time
   polymake_tree_hash = create_artifact() do art_dir
      mkpath(joinpath(art_dir,"deps"))
      deps = [ polymake_jll.FLINT_jll,
               polymake_jll.GMP_jll,
               polymake_jll.MPFR_jll,
               polymake_jll.PPL_jll,
               polymake_jll.Perl_jll,
               polymake_jll.bliss_jll,
               polymake_jll.boost_jll,
               polymake_jll.cddlib_jll,
               polymake_jll.lrslib_jll,
               polymake_jll.normaliz_jll ]
      for dep in deps
         symlink(full_artifact_dir(dep), joinpath(art_dir,"deps","$dep"))
      end
      for dir in readdir(polymake_jll.artifact_dir)
         symlink(joinpath(polymake_jll.artifact_dir,dir), joinpath(art_dir,dir))
      end
   end

   bind_artifact!(mutable_artifacts_toml,
      polymake_tree,
      polymake_tree_hash;
      force=true
   )

   # Point polymake to our custom tree
   return artifact_path(polymake_tree_hash)
end
