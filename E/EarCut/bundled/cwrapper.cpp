#include "./earcut.h"
template <typename T> using Polygon = std::vector<std::vector<T>>;
struct Arrayui32{
    uint32_t* data;
    int length;
};

using Pointf64 = std::pair<double, double>;
using Polygonf64 = Polygon<Pointf64>;

extern "C" {
    Arrayui32 u32_triangulate_f64(Pointf64** polygon, uint32_t* lengths, uint32_t len) {
        Polygonf64 v_polygon(len);
        for(int i = 0; i < len; i++){
            int len2 = lengths[i];
            std::vector<Pointf64> v_line(len2);
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

using Pointf32 = std::pair<float, float>;
using Polygonf32 = Polygon<Pointf32>;

extern "C" {
    Arrayui32 u32_triangulate_f32(Pointf32** polygon, uint32_t* lengths, uint32_t len) {
        Polygonf32 v_polygon(len);
        for(int i = 0; i < len; i++){
            int len2 = lengths[i];
            std::vector<Pointf32> v_line(len2);
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

using Pointi64 = std::pair<int64_t, int64_t>;
using Polygoni64 = Polygon<Pointi64>;

extern "C" {
    Arrayui32 u32_triangulate_i64(Pointi64** polygon, uint32_t* lengths, uint32_t len) {
        Polygoni64 v_polygon(len);
        for(int i = 0; i < len; i++){
            int len2 = lengths[i];
            std::vector<Pointi64> v_line(len2);
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

using Pointi32 = std::pair<int32_t, int32_t>;
using Polygoni32 = Polygon<Pointi32>;

extern "C" {
    Arrayui32 u32_triangulate_i32(Pointi32** polygon, uint32_t* lengths, uint32_t len) {
        Polygoni32 v_polygon(len);
        for(int i = 0; i < len; i++){
            int len2 = lengths[i];
            std::vector<Pointi32> v_line(len2);
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
