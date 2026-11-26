/* C interface to FUKA's initial data exporters, the functions the Einstein
 * Toolkit thorn KadathImporter calls. Not part of upstream FUKA. */

#ifndef FUKA_H
#define FUKA_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Types of initial data */
enum { FUKA_BH, FUKA_BBH, FUKA_NS, FUKA_BNS, FUKA_BHNS };

/* Fields, in output order. BH and BBH return the first FUKA_NUM_VAC_FIELDS
 * (lapse, shift, 3-metric, extrinsic curvature), the others all
 * FUKA_NUM_FIELDS (also rest-mass density, specific internal energy,
 * pressure, Eulerian 3-velocity). */
enum {
    FUKA_ALPHA,
    FUKA_BETAX, FUKA_BETAY, FUKA_BETAZ,
    FUKA_GXX, FUKA_GXY, FUKA_GXZ, FUKA_GYY, FUKA_GYZ, FUKA_GZZ,
    FUKA_KXX, FUKA_KXY, FUKA_KXZ, FUKA_KYY, FUKA_KYZ, FUKA_KZZ,
    FUKA_NUM_VAC_FIELDS,
    FUKA_RHO = FUKA_NUM_VAC_FIELDS, FUKA_EPS, FUKA_PRESS,
    FUKA_VELX, FUKA_VELY, FUKA_VELZ,
    FUKA_NUM_FIELDS
};

/* Number of fields fuka_export returns for `type`, or -1 for an unknown type */
int fuka_nfields(int type);

/* Evaluate the solution described by `info_file` (the path of a `.info`
 * file, with the `.dat` file of the same name next to it) at `npoints`
 * points with Cartesian coordinates `x`, `y`, `z`. Writes field `f` of
 * point `i` to `out[f * npoints + i]`; `out` holds
 * `fuka_nfields(type) * npoints` values.
 *
 * `interpolation_offset`, `interp_order` and `delta_r_rel` control how
 * points inside a black hole are filled (KadathImporter's defaults are 0,
 * 8 and 0.3); NS and BNS ignore them.
 *
 * A bare EOS file name in the `.info` file is looked up in
 * `$HOME_KADATH/eos`, or in the current directory if HOME_KADATH is unset.
 *
 * Calls are serialized. Each call reads the files again, so pass all points
 * at once. Returns 0 on success; otherwise returns -1 and, if `errlen > 0`,
 * writes a message to `errmsg`. */
int fuka_export(int type, const char *info_file, int64_t npoints,
                const double *x, const double *y, const double *z,
                double interpolation_offset, int interp_order,
                double delta_r_rel, double *out, char *errmsg,
                size_t errlen);

#ifdef __cplusplus
}
#endif

#endif
