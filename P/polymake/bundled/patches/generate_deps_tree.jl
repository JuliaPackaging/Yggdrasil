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

      # dependencies
      for dep in deps
         symlink(full_artifact_dir(dep), joinpath(art_dir,"deps","$dep"))
      end

      # polymake prefix directories
      for dir in filter(d -> d!="bin", readdir(polymake_jll.artifact_dir))
         symlink(joinpath(polymake_jll.artifact_dir,dir), joinpath(art_dir,dir))
      end

      # polymake perl scripts
      bindir(name) = joinpath(art_dir,"bin", name)
      mkpath(bindir(""))
      for file in ("polymake", "polymake-config")
         symlink(joinpath(polymake_jll.artifact_dir, "bin", file), bindir(file))
      end

      # wrappers for 4ti2 utilities which set the correct LIBPATH
      bindir4ti2 = joinpath(polymake_jll.lib4ti2_jll.artifact_dir,"bin")
      bin4ti2 = joinpath(bindir4ti2,"\$(basename \$0)")

      wrapper = bindir("4ti2_wrapper")
      write(wrapper, """
         #!/bin/sh
         # Since we cannot run these binaries through the usual julia commands we need
         # this wrapper that sets up the correct library paths.
         export $(polymake_jll.JLLWrappers.LIBPATH_env)="$(polymake_jll.lib4ti2_jll.LIBPATH[])"
         exec $(bin4ti2) "\$@"
         """)

      scriptwrapper = bindir("4ti2_script_wrapper")
      chmod(wrapper, 0o755)
      write(scriptwrapper, """
         #!/bin/sh
         # We cannot run the 4ti2 scripts directly as macOS will remove
         # DYLD_FALLBACK_LIBRARY_PATH for any subshells.
         # Instead we source the 4ti2 scripts, this means \$0 will still point to the
         # symlink in our wrapper directory. Since these scripts use \$0 to determine the
         # path of the real executable, they will execute our wrapper for the binary
         # (which will set up the library paths) instead of the original binary.
         # So we do not need to adjust any library paths here.
         source $(bin4ti2) "\$@"
         """)
      chmod(scriptwrapper, 0o755)

      for bin in readdir(bindir4ti2)
         if isfile(joinpath(bindir4ti2, bin))
            # a shell script starts with '#!'
            if read(joinpath(bindir4ti2, bin), 2) == UInt8['#', '!']
               symlink("4ti2_script_wrapper", bindir(bin))
            else
               symlink("4ti2_wrapper", bindir(bin))
            end
         end
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
