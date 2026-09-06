#ifndef _PDFORM_H
#define _PDFORM_H

/* Byte orders for float and int */
int
 lite_int_ord_f[] = {4, 3, 2, 1},
 lite_int_ord_d[] = {8, 7, 6, 5, 4, 3, 2, 1};

/* Bit layouts for float and double */
long
 lite_int_frm_f[] = {32L,  8L, 23L,  0L,  1L,  9L,  0L, 0x7FL},
 lite_int_frm_d[] = {64L, 11L, 52L,  0L,  1L, 12L,  0L, 0x3FFL};

/* Internal DATA_STANDARD */
data_standard
 lite_INT_STD = {4, /* size of pointer */
            2, REVERSE_ORDER, /* size and order of short */
            4, REVERSE_ORDER, /* size and order of int */
            4, REVERSE_ORDER, /* size and order of long */
            8, REVERSE_ORDER, /* size and order of long long */
            4, lite_int_frm_f, lite_int_ord_f, /* float definition */
            8, lite_int_frm_d, lite_int_ord_d}, /* double definition */
 *lite_INT_STANDARD = &lite_INT_STD;

/* Alignments for [char, char*, short, int, long, long long, float, double, (extra struct alignment)] */
data_alignment
 lite_INT_ALG = {1, 4, 2, 4, 4, 4, 4, 4, 0},
 *lite_INT_ALIGNMENT = &lite_INT_ALG;

#endif /* !_PDFORM_H */
