/*
 * Copyright (c) 2017, Miroslav Stoyanov
 *
 * This file is part of
 * Toolkit for Adaptive Stochastic Modeling And Non-Intrusive ApproximatioN: TASMANIAN
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 *    and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse
 *    or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * UT-BATTELLE, LLC AND THE UNITED STATES GOVERNMENT MAKE NO REPRESENTATIONS AND DISCLAIM ALL WARRANTIES, BOTH EXPRESSED AND IMPLIED.
 * THERE ARE NO EXPRESS OR IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, OR THAT THE USE OF THE SOFTWARE WILL NOT INFRINGE ANY PATENT,
 * COPYRIGHT, TRADEMARK, OR OTHER PROPRIETARY RIGHTS, OR THAT THE SOFTWARE WILL ACCOMPLISH THE INTENDED RESULTS OR THAT THE SOFTWARE OR ITS USE WILL NOT RESULT IN INJURY OR DAMAGE.
 * THE USER ASSUMES RESPONSIBILITY FOR ALL LIABILITIES, PENALTIES, FINES, CLAIMS, CAUSES OF ACTION, AND COSTS AND EXPENSES, CAUSED BY, RESULTING FROM OR ARISING OUT OF,
 * IN WHOLE OR IN PART THE USE, STORAGE OR DISPOSAL OF THE SOFTWARE.
 */

#ifndef __TASMANIAN_BLAS_WRAPPERS_HPP
#define __TASMANIAN_BLAS_WRAPPERS_HPP

#include "tsgEnumerates.hpp"

/*!
 * \internal
 * \file tsgBlasWrappers.hpp
 * \brief Wrappers to BLAS functionality.
 * \author Miroslav Stoyanov
 * \ingroup TasmanianTPLWrappers
 *
 * The header contains a inline wrappers that give C++ style of
 * interface to BLAS operations.
 * \endinternal
 */

#ifndef __TASMANIAN_DOXYGEN_SKIP
extern "C"{
// Skip the definitions from Doxygen, this serves as a mock-up header for the BLAS API.
// BLAS level 1
double dnrm2_64_(const int64_t *N, const double *x, const int64_t *incx);
void dswap_64_(const int64_t *N, double *x, const int64_t *incx, double *y, const int64_t *incy);
void dscal_64_(const int64_t *N, const double *alpha, const double *x, const int64_t *incx);
// BLAS level 2
void dgemv_64_(const char *transa, const int64_t *M, const int64_t *N, const double *alpha, const double *A, const int64_t *lda,
            const double *x, const int64_t *incx, const double *beta, const double *y, const int64_t *incy);
void dtrsv_64_(const char *uplo, const char *trans, const char *diag, const int64_t *N, const double *A, const int64_t *lda,
            double *x, const int64_t *incx);
// BLAS level 3
void dgemm_64_(const char* transa, const char* transb, const int64_t *m, const int64_t *n, const int64_t *k, const double *alpha,
            const double *A, const int64_t *lda, const double *B, const int64_t *ldb, const double *beta, const double *C, const int64_t *ldc);
void dtrsm_64_(const char *side, const char *uplo, const char *trans, const char *diag, const int64_t *M, const int64_t *N,
            const double *alpha, const double *A, const int64_t *lda, double *B, const int64_t *ldb);
void ztrsm_64_(const char *side, const char *uplo, const char *trans, const char *diag, const int64_t *M, const int64_t *N,
            const std::complex<double> *alpha, const std::complex<double> *A, const int64_t *lda, std::complex<double> *B, const int64_t *ldb);
// LAPACK solvers
// General PLU factorize/solve
void dgetrf_64_(const int64_t *M, const int64_t *N, double *A, const int64_t *lda, int64_t *ipiv, int64_t *info);
void dgetrs_64_(const char *trans, const int64_t *N, const int64_t *nrhs, const double *A, const int64_t *lda, const int64_t *ipiv, double *B, const int64_t *ldb, int64_t *info);
// General least-squares solve
void dgels_64_(const char *trans, const int64_t *M, const int64_t *N, const int64_t *nrhs, double *A, const int64_t *lda,
            double *B, const int64_t *ldb, double *work, int64_t *lwork, int64_t *info);
void zgels_64_(const char *trans, const int64_t *M, const int64_t *N, const int64_t *nrhs, std::complex<double> *A, const int64_t *lda,
            std::complex<double> *B, const int64_t *ldb, std::complex<double> *work, int64_t *lwork, int64_t *info);
// Symmetric tridiagonal eigenvalue compute
void dstebz_64_(const char *range, const char *order, const int64_t *N, const double *vl, const double *vu, const int64_t *il, const int64_t *iu, const double *abstol,
             const double D[], const double E[], int64_t *M, int64_t *nsplit, double W[], int64_t iblock[], int64_t isplit[], double work[], int64_t iwork[], int64_t *info);
void dsteqr_64_(const char *compz, const int64_t *N, double D[], double E[], double Z[], const int64_t *ldz, double work[], int64_t *info);
void dsterf_64_(const int64_t *N, double D[], double E[], int64_t *info);
// General LQ-factorize and multiply by Q
#ifdef Tasmanian_BLAS_HAS_ZGELQ
void dgelq_64_(const int64_t *M, const int64_t *N, double *A, const int64_t *lda, double *T, int64_t const *Tsize, double *work, int64_t const *lwork, int64_t *info);
void dgemlq_64_(const char *side, const char *trans, const int64_t *M, const int64_t *N, const int64_t *K, double const *A, int64_t const *lda,
             double const *T, int64_t const *Tsize, double C[], int64_t const *ldc, double *work, int64_t const *lwork, int64_t *info);
void zgelq_64_(const int64_t *M, const int64_t *N, std::complex<double> *A, const int64_t *lda, std::complex<double> *T, int64_t const *Tsize,
            std::complex<double> *work, int64_t const *lwork, int64_t *info);
void zgemlq_64_(const char *side, const char *trans, const int64_t *M, const int64_t *N, const int64_t *K, std::complex<double> const *A, int64_t const *lda,
             std::complex<double> const *T, int64_t const *Tsize, std::complex<double> C[], int64_t const *ldc, std::complex<double> *work, int64_t const *lwork, int64_t *info);
#endif
}
#endif

/*!
 * \ingroup TasmanianTPLWrappers
 * \brief Wrappers for BLAS and LAPACK methods (hidden internal namespace).
 */
namespace TasBLAS{
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief BLAS dnrm2
     */
    inline double norm2(int64_t N, double const x[], int64_t incx){
        return dnrm2_64_(&N, x, &incx);
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief BLAS dswap
     */
    inline void vswap(int64_t N, double x[], int64_t incx, double y[], int64_t incy){
        dswap_64_(&N, x, &incx, y, &incy);
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief BLAS dscal
     */
    inline void scal(int64_t N, double alpha, double x[], int64_t incx){
        dscal_64_(&N, &alpha, x, &incx);
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief BLAS dgemv
     */
    inline void gemv(char trans, int64_t M, int64_t N, double alpha, double const A[], int64_t lda, double const x[], int64_t incx,
                     double beta, double y[], int64_t incy){
        dgemv_64_(&trans, &M, &N, &alpha, A, &lda, x, &incx, &beta, y, &incy);
    }

  /*!
     * \ingroup TasmanianTPLWrappers
     * \brief BLAS dtrsv
     */
    inline void trsv(char uplo, char trans, char diag, int64_t N, double const A[], int64_t lda, double x[], int64_t incx){
        dtrsv_64_(&uplo, &trans, &diag, &N, A, &lda, x, &incx);
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief BLAS gemm
     */
    inline void gemm(char transa, char transb, int64_t M, int64_t N, int64_t K, double alpha, double const A[], int64_t lda, double const B[], int64_t ldb,
                     double beta, double C[], int64_t ldc){
        dgemm_64_(&transa, &transb, &M, &N, &K, &alpha, A, &lda, B, &ldb, &beta, C, &ldc);
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief BLAS dtrsm
     */
    inline void trsm(char side, char uplo, char trans, char diag, int64_t M, int64_t N, double alpha, double const A[], int64_t lda, double B[], int64_t ldb){
        dtrsm_64_(&side, &uplo, &trans, &diag, &M, &N, &alpha, A, &lda, B, &ldb);
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief BLAS ztrsm
     */
    inline void trsm(char side, char uplo, char trans, char diag, int64_t M, int64_t N, std::complex<double> alpha,
                     std::complex<double> const A[], int64_t lda, std::complex<double> B[], int64_t ldb){
        ztrsm_64_(&side, &uplo, &trans, &diag, &M, &N, &alpha, A, &lda, B, &ldb);
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK dgetrf
     */
    inline void getrf(int64_t M, int64_t N, double A[], int64_t lda, int64_t ipiv[]){
        int64_t info = 0;
        dgetrf_64_(&M, &N, A, &lda, ipiv, &info);
        if (info != 0) throw std::runtime_error(std::string("Lapack dgetrf_ exited with code: ") + std::to_string(info));
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK dgetrs
     */
    inline void getrs(char trans, int64_t N, int64_t nrhs, double const A[], int64_t lda, int64_t const ipiv[], double B[], int64_t ldb){
        int64_t info = 0;
        dgetrs_64_(&trans, &N, &nrhs, A, &lda, ipiv, B, &ldb, &info);
        if (info != 0) throw std::runtime_error(std::string("Lapack dgetrs_ exited with code: ") + std::to_string(info));
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK dgels
     */
    inline void gels(char trans, int64_t M, int64_t N, int64_t nrhs, double A[], int64_t lda, double B[], int64_t ldb, double work[], int64_t lwork){
        int64_t info = 0;
        dgels_64_(&trans, &M, &N, &nrhs, A, &lda, B, &ldb, work, &lwork, &info);
        if (info != 0){
            if (lwork > 0)
                throw std::runtime_error(std::string("Lapack dgels_ solve-stage exited with code: ") + std::to_string(info));
            else
                throw std::runtime_error(std::string("Lapack dgels_ infer-worksize-stage exited with code: ") + std::to_string(info));
        }
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK zgels
     */
    inline void gels(char trans, int64_t M, int64_t N, int64_t nrhs, std::complex<double> A[], int64_t lda, std::complex<double> B[], int64_t ldb, std::complex<double> work[], int64_t lwork){
        int64_t info = 0;
        zgels_64_(&trans, &M, &N, &nrhs, A, &lda, B, &ldb, work, &lwork, &info);
        if (info != 0){
            if (lwork > 0)
                throw std::runtime_error(std::string("Lapack zgels_ solve-stage exited with code: ") + std::to_string(info));
            else
                throw std::runtime_error(std::string("Lapack zgels_ infer-worksize-stage exited with code: ") + std::to_string(info));
        }
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK dstebz
     */
    inline void stebz(char range, char order, int64_t N, double vl, double vu, int64_t il, int64_t iu, double abstol, double D[], double E[],
                      int64_t M, int64_t nsplit, double W[], int64_t iblock[], int64_t isplit[], double work[], int64_t iwork[]) {
        int64_t info = 0;
        dstebz_64_(&range, &order, &N, &vl, &vu, &il, &iu, &abstol, D, E, &M, &nsplit, W, iblock, isplit, work, iwork, &info);
        if (info != 0) {
            if (info <= 3) {
                throw std::runtime_error(
                    std::string(
                        "Lapack dstebz_ failed to converge for some eigenvalues and exited with code: ") +
                    std::to_string(info));
            } else if (info == 4) {
                throw std::runtime_error(
                    std::string("Lapack dstebz_ used a Gershgorin interval that was too small and exited with code: ") +
                    std::to_string(info));
            } else if (info > 4) {
                throw std::runtime_error(
                    std::string("Lapack dstebz_ failed and exited with code: ") +
                    std::to_string(info));
            } else {
                throw std::runtime_error(
                    std::string(
                        "Lapack dstebz_ had an illegal value at argument number: ") +
                    std::to_string(-info));
            }
        }
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK dsteqr
     */
    inline void steqr(char compz, int64_t N, double D[], double E[], double Z[], int64_t ldz, double work[]) {
        int64_t info = 0;
        dsteqr_64_(&compz, &N, D, E, Z, &ldz, work, &info);
        if (info != 0) {
            if (info > 0) {
                throw std::runtime_error(
                    std::string("Lapack dsteqr_ failed to converge for some eigenvalues and exited with code: ") +
                    std::to_string(info));
            } else {
                throw std::runtime_error(
                    std::string("Lapack dsteqr_ had an illegal value at argument number: ") +
                    std::to_string(-info));
            }
        }
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK dsterf
     */
    inline void sterf(int64_t N, double D[], double E[]) {
        int64_t info = 0;
        dsterf_64_(&N, D, E, &info);
        if (info != 0) {
            if (info > 0) {
                throw std::runtime_error(
                    std::string("Lapack dsteqr_ failed to converge for some eigenvalues and exited with code: ") +
                    std::to_string(info));
            } else {
                throw std::runtime_error(
                    std::string("Lapack dsteqr_ had an illegal value at argument number: ") +
                    std::to_string(-info));
            }
        }
    }
#ifdef Tasmanian_BLAS_HAS_ZGELQ
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK dgeql
     */
    inline void geql(int64_t M, int64_t N, double A[], int64_t lda, double T[], int64_t Tsize, double work[], int64_t lwork){
        int64_t info = 0;
        dgelq_64_(&M, &N, A, &lda, T, &Tsize, work, &lwork, &info);
        if (info != 0){
            if (lwork > 0)
                throw std::runtime_error(std::string("Lapack dgeql_ factorize-stage exited with code: ") + std::to_string(info));
            else
                throw std::runtime_error(std::string("Lapack dgeql_ infer-worksize-stage exited with code: ") + std::to_string(info));
        }
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK dgemlq
     */
    inline void gemlq(char side, char trans, int64_t M, int64_t N, int64_t K, double const A[], int64_t lda, double const T[], int64_t Tsize,
                       double C[], int64_t ldc, double work[], int64_t lwork){
        int64_t info = 0;
        dgemlq_64_(&side, &trans, &M, &N, &K, A, &lda, T, &Tsize, C, &ldc, work, &lwork, &info);
        if (info != 0){
            if (lwork > 0)
                throw std::runtime_error(std::string("Lapack dgemlq_ compute-stage exited with code: ") + std::to_string(info));
            else
                throw std::runtime_error(std::string("Lapack dgemlq_ infer-worksize-stage exited with code: ") + std::to_string(info));
        }
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK zgeql
     */
    inline void geql(int64_t M, int64_t N, std::complex<double> A[], int64_t lda, std::complex<double> T[], int64_t Tsize, std::complex<double> work[], int64_t lwork){
        int64_t info = 0;
        zgelq_64_(&M, &N, A, &lda, T, &Tsize, work, &lwork, &info);
        if (info != 0){
            if (lwork > 0)
                throw std::runtime_error(std::string("Lapack zgeql_ factorize-stage exited with code: ") + std::to_string(info));
            else
                throw std::runtime_error(std::string("Lapack zgeql_ infer-worksize-stage exited with code: ") + std::to_string(info));
        }
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief LAPACK zgemlq
     */
    inline void gemlq(char side, char trans, int64_t M, int64_t N, int64_t K, std::complex<double> const A[], int64_t lda, std::complex<double> const T[], int64_t Tsize,
                       std::complex<double> C[], int64_t ldc, std::complex<double> work[], int64_t lwork){
        int64_t info = 0;
        zgemlq_64_(&side, &trans, &M, &N, &K, A, &lda, T, &Tsize, C, &ldc, work, &lwork, &info);
        if (info != 0){
            if (lwork > 0)
                throw std::runtime_error(std::string("Lapack zgemlq_ compute-stage exited with code: ") + std::to_string(info));
            else
                throw std::runtime_error(std::string("Lapack zgemlq_ infer-worksize-stage exited with code: ") + std::to_string(info));
        }
    }
    #endif

    // higher-level methods building on top of one or more BLAS/LAPACK Methods

    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Returns the square of the norm of the vector.
     */
    template<typename T>
    inline T norm2_2(int64_t N, T const x[]){
        T nrm = norm2(N, x, 1);
        return nrm * nrm;
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Combination of BLAS gemm and gemv
     *
     * Computes \f$ C = \alpha A B + \beta C \f$ where A is M by K, B is K by N, and C is M by N.
     * The method uses both gemm() and gemv() to handle the cases when either dimension is one.
     */
    template<typename T>
    inline void denseMultiply(int64_t M, int64_t N, int64_t K, T alpha, const T A[], const T B[], T beta, T C[]){
        if (M > 1){
            if (N > 1){ // matrix mode
                gemm('N', 'N', M, N, K, alpha, A, M, B, K, beta, C, M);
            }else{ // matrix vector, A * v = C
                gemv('N', M, K, alpha, A, M, B, 1, beta, C, 1);
            }
        }else{ // matrix vector B^T * v = C
            gemv('T', K, N, alpha, B, K, A, 1, beta, C, 1);
        }
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Conjugates a matrix, no op in the real case.
     */
    inline void conj_matrix(int, int, double[]){}
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Conjugates the matrix, used in the case when 'T' operation is needed by only 'C' is available in the LAPACK standard.
     */
    inline void conj_matrix(int64_t N, int64_t M, std::complex<double> A[]){
        for(size_t i=0; i<static_cast<size_t>(N) * static_cast<size_t>(M); i++) A[i] = std::conj(A[i]);
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Returns the transpose symbol, 'T' in the real case.
     */
    constexpr inline char get_trans(double){ return 'T'; }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Returns the conjugate-transpose symbol, 'C' in the complex case.
     */
    constexpr inline char get_trans(std::complex<double>){ return 'C'; }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Solves the over-determined least squares problem with single right-hand-side.
     *
     * Note that trans must be a capital letter N or T.
     */
    template<typename scalar_type>
    inline void solveLS(char trans, int64_t N, int64_t M, scalar_type A[], scalar_type b[], int64_t nrhs = 1){
        std::vector<scalar_type> work(1);
        int64_t n = (trans == 'N') ? N : M;
        int64_t m = (trans == 'N') ? M : N;
        char effective_trans = (trans == 'N') ? trans : get_trans(static_cast<scalar_type>(0.0));
        conj_matrix(N, M, A); // does nothing in the real case, computes the conjugate in the complex one
        TasBLAS::gels(effective_trans, n, m, nrhs, A, n, b, N, work.data(), -1);
        work.resize(static_cast<size_t>(std::real(work[0])));
        TasBLAS::gels(effective_trans, n, m, nrhs, A, n, b, N, work.data(), static_cast<int>(work.size()));
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Compute the LQ factorization of the matrix \b A.
     *
     * The assumption here is that the matrix is in column major format, otherwise this computes the QR factorization.
     * In fact, the Tasmanian uses this method to compute QR of a row-major matrix.
     */
    template<typename scalar_type>
    inline void factorizeLQ(int64_t rows, int64_t cols, scalar_type A[], std::vector<scalar_type> &T){
        T.resize(5);
        std::vector<scalar_type> work(1);
        geql(rows, cols, A, rows, T.data(), -1, work.data(), -1);
        T.resize(static_cast<size_t>(std::real(T[0])));
        work.resize(static_cast<size_t>(std::real(work[0])));
        geql(rows, cols, A, rows, T.data(), static_cast<int>(T.size()), work.data(), static_cast<int>(work.size()));
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Multiplies C by the Q factor computed with factorizeLQ.
     *
     * Computes \f$ C = C Q^T \f$ where Q comes from the call to factorizeLQ.
     * The matrix C has dimensions M by N, A has dimensions K by N.
     */
    template<typename scalar_type>
    inline void multiplyQ(int64_t M, int64_t N, int64_t K, scalar_type const A[], std::vector<scalar_type> const &T, scalar_type C[]){
        std::vector<scalar_type> work(1);
        gemlq('R', get_trans(static_cast<scalar_type>(0.0)), M, N, K, A, K, T.data(), static_cast<int>(T.size()), C, M, work.data(), -1);
        work.resize(static_cast<int>(std::real(work[0])));
        gemlq('R', get_trans(static_cast<scalar_type>(0.0)), M, N, K, A, K, T.data(), static_cast<int>(T.size()), C, M, work.data(), static_cast<int>(work.size()));
    }
    /*!
     * \ingroup TasmanianTPLWrappers
     * \brief Solves the least-squares assuming row-major format, see TasmanianDenseSolver::solvesLeastSquares()
     */
    template<typename scalar_type>
    void solveLSmulti(int64_t n, int64_t m, scalar_type A[], int64_t nrhs, scalar_type B[]){
        if (nrhs == 1){
            TasBLAS::solveLS('T', n, m, A, B);
        }else{
            #ifdef Tasmanian_BLAS_HAS_ZGELQ
            std::vector<scalar_type> T;
            TasBLAS::factorizeLQ(m, n, A, T);
            TasBLAS::multiplyQ(nrhs, n, m, A, T, B);
            TasBLAS::trsm('R', 'L', 'N', 'N', nrhs, m, 1.0, A, m, B, nrhs);
            #else
            auto Bcols = TasGrid::Utils::transpose(nrhs, n, B);
            TasBLAS::solveLS('T', n, m, A, Bcols.data(), nrhs);
            TasGrid::Utils::transpose(n, nrhs, Bcols.data(), B);
            #endif
        }
    }
}

#endif
