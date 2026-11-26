#include "fuka.h"

#include <array>
#include <climits>
#include <cstdio>
#include <exception>
#include <mutex>
#include <string>
#include <vector>

// Defined in libkadath (src/Utilities/Exporters), declared in no FUKA
// header; these declarations are copied from KadathImporter's importer.h.
using vac_fields = std::array<std::vector<double>, FUKA_NUM_VAC_FIELDS>;
using all_fields = std::array<std::vector<double>, FUKA_NUM_FIELDS>;
vac_fields KadathExportBH(int, const double *, const double *, const double *,
                          const char *, double, int, double);
vac_fields KadathExportBBH(int, const double *, const double *, const double *,
                           const char *, double, int, double);
all_fields KadathExportNS(int, const double *, const double *, const double *,
                          const char *);
all_fields KadathExportBNS(int, const double *, const double *, const double *,
                           const char *);
all_fields KadathExportBHNS(int, const double *, const double *, const double *,
                            const char *, double, int, double);

namespace {

// Kadath keeps global state (memory pools, FFTW plans, the EOS)
std::mutex fuka_mutex;

bool file_exists(const std::string &path) {
    FILE *f = std::fopen(path.c_str(), "rb");
    if (f)
        std::fclose(f);
    return f != nullptr;
}

template <std::size_t N>
void copy_fields(const std::array<std::vector<double>, N> &fields,
                 int64_t npoints, double *out) {
    for (std::size_t f = 0; f < N; ++f)
        for (int64_t i = 0; i < npoints; ++i)
            out[f * npoints + i] = fields[f].at(i);
}

}

extern "C" int fuka_nfields(int type) {
    switch (type) {
    case FUKA_BH:
    case FUKA_BBH:
        return FUKA_NUM_VAC_FIELDS;
    case FUKA_NS:
    case FUKA_BNS:
    case FUKA_BHNS:
        return FUKA_NUM_FIELDS;
    default:
        return -1;
    }
}

extern "C" int fuka_export(int type, const char *info_file, int64_t npoints,
                           const double *x, const double *y, const double *z,
                           double interpolation_offset, int interp_order,
                           double delta_r_rel, double *out, char *errmsg,
                           size_t errlen) {
    auto fail = [&](const std::string &msg) {
        if (errlen > 0)
            std::snprintf(errmsg, errlen, "%s", msg.c_str());
        return -1;
    };
    try {
        if (fuka_nfields(type) < 0)
            return fail("unknown type of initial data " + std::to_string(type));
        if (npoints < 0 || npoints > INT_MAX)
            return fail("npoints out of range: " + std::to_string(npoints));
        // Kadath crashes on a missing .dat file instead of reporting it.
        // KadathExportBHNS requires the name to end in ".info".
        const std::string info(info_file);
        const std::string suffix = ".info";
        if (info.size() <= suffix.size() ||
            info.compare(info.size() - suffix.size(), suffix.size(), suffix) != 0)
            return fail("file name does not end in \".info\": " + info);
        const std::string dat = info.substr(0, info.size() - suffix.size()) + ".dat";
        for (const auto &path : {info, dat})
            if (!file_exists(path))
                return fail("cannot read file " + path);

        const int n = int(npoints);
        std::lock_guard<std::mutex> lock(fuka_mutex);
        switch (type) {
        case FUKA_BH:
            copy_fields(KadathExportBH(n, x, y, z, info_file, interpolation_offset,
                                       interp_order, delta_r_rel),
                        npoints, out);
            break;
        case FUKA_BBH:
            copy_fields(KadathExportBBH(n, x, y, z, info_file, interpolation_offset,
                                        interp_order, delta_r_rel),
                        npoints, out);
            break;
        case FUKA_NS:
            copy_fields(KadathExportNS(n, x, y, z, info_file), npoints, out);
            break;
        case FUKA_BNS:
            copy_fields(KadathExportBNS(n, x, y, z, info_file), npoints, out);
            break;
        case FUKA_BHNS:
            copy_fields(KadathExportBHNS(n, x, y, z, info_file, interpolation_offset,
                                         interp_order, delta_r_rel),
                        npoints, out);
            break;
        }
        return 0;
    } catch (const std::exception &e) {
        return fail(e.what());
    } catch (...) {
        return fail("unknown C++ exception");
    }
}
