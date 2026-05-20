#
# generate_cwrapper.jl for tetgen copied from JuliaGeometry/tetgenbuilder
# In the moment this file is dormant.
#

# (c) Simon Danisch

# Permission is hereby granted, free  of charge, to any person obtaining
# a  copy  of this  software  and  associated documentation  files  (the
# "Software"), to  deal in  the Software without  restriction, including
# without limitation  the rights to  use, copy, modify,  merge, publish,
# distribute, sublicense,  and/or sell  copies of  the Software,  and to
# permit persons to whom the Software  is furnished to do so, subject to
# the following conditions:

# The  above  copyright  notice  and this  permission  notice  shall  be
# included in all copies or substantial portions of the Software.

# THE  SOFTWARE IS  PROVIDED  "AS  IS", WITHOUT  WARRANTY  OF ANY  KIND,
# EXPRESS OR  IMPLIED, INCLUDING  BUT NOT LIMITED  TO THE  WARRANTIES OF
# MERCHANTABILITY,    FITNESS    FOR    A   PARTICULAR    PURPOSE    AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING  FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

cd(@__DIR__)
open("cwrapper.cpp", "w") do io
    println(io, """
    #include "tetgen.h" // Defined tetgenio, tetrahedralize().
    """)


    for (REAL, ext) in ["double" => "f64"]
        println(io, """
        typedef struct {
          int firstnumber; // 0 or 1, default 0.
          int mesh_dim;    // must be 3.

          $REAL *pointlist;
          $REAL *pointattributelist;
          $REAL *pointmtrlist;
          int *pointmarkerlist;
          int numberofpoints;
          int numberofpointattributes;
          int numberofpointmtrs;

          int *tetrahedronlist;
          $REAL *tetrahedronattributelist;
          $REAL *tetrahedronvolumelist;
          int *neighborlist;
          int numberoftetrahedra;
          int numberofcorners;
          int numberoftetrahedronattributes;

          tetgenio::facet *facetlist;
          int *facetmarkerlist;
          int numberoffacets;

          $REAL *holelist;
          int numberofholes;

          $REAL *regionlist;
          int numberofregions;

          $REAL *facetconstraintlist;
          int numberoffacetconstraints;

          $REAL *segmentconstraintlist;
          int numberofsegmentconstraints;

          int *trifacelist;
          int *trifacemarkerlist;
          int numberoftrifaces;

          int *edgelist;
          int *edgemarkerlist;
          int numberofedges;
        } TetGenIO$ext;

        void copy_tetio(tetgenio* in, TetGenIO$ext* out){
            out->firstnumber = in->firstnumber;
            out->mesh_dim = in->mesh_dim;

            out->pointlist = in->pointlist;
            out->pointattributelist = in->pointattributelist;
            out->pointmtrlist = in->pointmtrlist;
            out->pointmarkerlist = in->pointmarkerlist;
            out->numberofpoints = in->numberofpoints;
            out->numberofpointattributes = in->numberofpointattributes;
            out->numberofpointmtrs = in->numberofpointmtrs;

            out->tetrahedronlist = in->tetrahedronlist;
            out->tetrahedronattributelist = in->tetrahedronattributelist;
            out->tetrahedronvolumelist = in->tetrahedronvolumelist;
            out->neighborlist = in->neighborlist;
            out->numberoftetrahedra = in->numberoftetrahedra;
            out->numberofcorners = in->numberofcorners;
            out->numberoftetrahedronattributes = in->numberoftetrahedronattributes;

            out->facetlist = in->facetlist;
            out->facetmarkerlist = in->facetmarkerlist;
            out->numberoffacets = in->numberoffacets;

            out->holelist = in->holelist;
            out->numberofholes = in->numberofholes;

            out->regionlist = in->regionlist;
            out->numberofregions = in->numberofregions;

            out->facetconstraintlist = in->facetconstraintlist;
            out->numberoffacetconstraints = in->numberoffacetconstraints;

            out->segmentconstraintlist = in->segmentconstraintlist;
            out->numberofsegmentconstraints = in->numberofsegmentconstraints;

            out->trifacelist = in->trifacelist;
            out->trifacemarkerlist = in->trifacemarkerlist;
            out->numberoftrifaces = in->numberoftrifaces;

            out->edgelist = in->edgelist;
            out->edgemarkerlist = in->edgemarkerlist;
            out->numberofedges = in->numberofedges;

        }
        void copy_tetio(TetGenIO$ext* in, tetgenio* out){
            out->firstnumber = in->firstnumber;
            out->mesh_dim = in->mesh_dim;

            out->pointlist = in->pointlist;
            out->pointattributelist = in->pointattributelist;
            out->pointmtrlist = in->pointmtrlist;
            out->pointmarkerlist = in->pointmarkerlist;
            out->numberofpoints = in->numberofpoints;
            out->numberofpointattributes = in->numberofpointattributes;
            out->numberofpointmtrs = in->numberofpointmtrs;

            out->tetrahedronlist = in->tetrahedronlist;
            out->tetrahedronattributelist = in->tetrahedronattributelist;
            out->tetrahedronvolumelist = in->tetrahedronvolumelist;
            out->neighborlist = in->neighborlist;
            out->numberoftetrahedra = in->numberoftetrahedra;
            out->numberofcorners = in->numberofcorners;
            out->numberoftetrahedronattributes = in->numberoftetrahedronattributes;

            out->facetlist = in->facetlist;
            out->facetmarkerlist = in->facetmarkerlist;
            out->numberoffacets = in->numberoffacets;

            out->holelist = in->holelist;
            out->numberofholes = in->numberofholes;

            out->regionlist = in->regionlist;
            out->numberofregions = in->numberofregions;

            out->facetconstraintlist = in->facetconstraintlist;
            out->numberoffacetconstraints = in->numberoffacetconstraints;

            out->segmentconstraintlist = in->segmentconstraintlist;
            out->numberofsegmentconstraints = in->numberofsegmentconstraints;

            out->trifacelist = in->trifacelist;
            out->trifacemarkerlist = in->trifacemarkerlist;
            out->numberoftrifaces = in->numberoftrifaces;

            out->edgelist = in->edgelist;
            out->edgemarkerlist = in->edgemarkerlist;
            out->numberofedges = in->numberofedges;

        }
        extern "C" {

          TetGenIO$ext tetrahedralize$ext(TetGenIO$ext jl_in, char* command){
            tetgenio in, out;
            copy_tetio(&jl_in, &in);
            tetrahedralize(command, &in, &out);
            TetGenIO$ext jl_out;
            copy_tetio(&out, &jl_out);
            in.initialize(); // don't free pointers from julia!
            out.initialize(); // don't free pointers for julia!
            return jl_out;
          }

        }

        """)
    end
end
