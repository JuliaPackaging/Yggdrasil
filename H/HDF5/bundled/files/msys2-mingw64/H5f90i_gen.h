/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright by The HDF Group.                                               *
 * All rights reserved.                                                      *
 *                                                                           *
 * This file is part of HDF5.  The full HDF5 copyright notice, including     *
 * terms governing use, modification, and redistribution, is contained in    *
 * the COPYING file, which can be found at the root of the source code       *
 * distribution tree, or in https://www.hdfgroup.org/licenses.               *
 * If you do not have access to either file, you may request a copy from     *
 * help@hdfgroup.org.                                                        *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


#ifndef H5f90i_gen_H
#define H5f90i_gen_H

/* This file is automatically generated by H5match_types.c at build time. */

#include "H5public.h"

#define c_int_1 char
#define c_int_2 short
#define c_int_4 long
#define c_int_8 long long
#define c_size_t_8 size_t
#define c_time_t_8 time_t
#define c_hsize_t_8 hsize_t
typedef struct {c_int_8 a; c_int_8 b;} c_int_16;
#define c_float_4 float
#define c_float_8 double
#define c_float_10 long double
#define c_float_16 __float128

typedef c_int_8 haddr_t_f;
typedef c_hsize_t_8 hsize_t_f;
typedef c_int_8 hssize_t_f;
typedef c_int_8 off_t_f;
typedef c_size_t_8 size_t_f;
typedef c_time_t_8 time_t_f;
typedef c_int_4 int_f;
typedef c_float_4 real_C_FLOAT_f;
typedef c_float_8 real_C_DOUBLE_f;
typedef c_float_10 real_C_LONG_DOUBLE_f;
typedef c_float_16 real_C_FLOAT128_f;
typedef c_int_8 hid_t_f;
typedef c_float_4 real_f;
typedef c_float_8 double_f;

#endif /* _H5f90i_gen_H */
