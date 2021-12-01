
function jl_string(jltyp, pscript)
    """
    function triangulate(polygon::Vector{Vector{Point{2, $jltyp}}})
        lengths = map(x-> UInt32(length(x)), polygon)
        len = UInt32(length(lengths))
        array = ccall(
            (:u32_triangulate_$pscript, lib),
            Tuple{Ptr{GLTriangle}, Cint},
            (Ptr{Ptr{$jltyp}}, Ptr{UInt32}, UInt32),
            polygon, lengths, len
        )
        unsafe_wrap(Vector{GLTriangle}, array[1], array[2])
    end
    """
end
function c_string(ctyp, pscript)
    ptype = "Point"*pscript
    polytype = "Polygon"*pscript
    """
    using $ptype = std::pair<$ctyp, $ctyp>;
    using $polytype = Polygon<$ptype>;

    extern "C" {
        Arrayui32 u32_triangulate_$pscript($ptype** polygon, uint32_t* lengths, uint32_t len) {
            $polytype v_polygon(len);
            for(int i = 0; i < len; i++){
                int len2 = lengths[i];
                std::vector<$ptype> v_line(len2);
                for(int j = 0; j < len2; j++){
                    v_line[j] = polygon[i][j];
                }
                v_polygon[i] = v_line;
            }
            std::vector<uint32_t> indices = mapbox::earcut<uint32_t>(v_polygon);
            uint32_t *result;
            int n = indices.size();
            result = new uint32_t[n];
            for(int i = 0; i < n; i++){
                result[i] = indices[i];
            }
            struct Arrayui32 result_array;
            result_array.data = result;
            result_array.length = n / 3; //these are triangles in real life
            return result_array;
        }
    }
    """
end
types = [
    (Float64, "double", "f64"),
    (Float32, "float", "f32"),
    (Int64, "int64_t", "i64"),
    (Int32, "int32_t", "i32")
]
dir(files...) = joinpath(dirname(@__FILE__), files...)
isdir(dir("products")) || mkdir(dir("products"))

jlfile = open(dir("products", "cwrapper.jl"), "w")
cfile = open(dir("cwrapper.cpp"), "w")

println(jlfile, """
const lib = Libdl.find_library(
    ["earcut"],
    [joinpath(dirname(@__FILE__), "..", "deps", "build")]
)
if isempty(lib)
    error("Library not found. Please run Pkg.build(\\\"EarCut\\\").")
end
""")

println(cfile, """
#include "earcut.hpp"
template <typename T> using Polygon = std::vector<std::vector<T>>;
struct Arrayui32{
    uint32_t* data;
    int length;
};
""")

for (jltyp, ctyp, pscript) in types
    println(jlfile, jl_string(jltyp, pscript))
    println(cfile, c_string(ctyp, pscript))
end
close(jlfile); close(cfile)
