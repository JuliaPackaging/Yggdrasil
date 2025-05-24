#include "helpers.h"

Eigen::SparseMatrix<double, Eigen::ColMajor, int>
mapSparseJuliaArray(jlcxx::ArrayRef<std::int64_t, 1> x_colptr,
                    jlcxx::ArrayRef<std::int64_t, 1> x_rowval,
                    jlcxx::ArrayRef<double, 1> x_vals,
                    std::int64_t n,
                    std::int64_t p)
{
  // Create adjusted copies of the index arrays (1-indexed to 0-indexed)
  // TODO: Can we avoid these copies?
  std::vector<int> adjusted_colptr(x_colptr.size());
  std::vector<int> adjusted_rowval(x_rowval.size());

  for (size_t i = 0; i < x_colptr.size(); ++i) {
    adjusted_colptr[i] = static_cast<int>(x_colptr[i] - 1);
  }

  for (size_t i = 0; i < x_rowval.size(); ++i) {
    adjusted_rowval[i] = static_cast<int>(x_rowval[i] - 1);
  }

  // Create sparse matrix using Map with explicit storage type
  return Eigen::Map<Eigen::SparseMatrix<double, Eigen::ColMajor, int>>(
    static_cast<Eigen::Index>(n),
    static_cast<Eigen::Index>(p),
    static_cast<int>(x_vals.size()),   // nnz (number of non-zeros)
    adjusted_colptr.data(),            // outerIndexPtr (column pointers)
    adjusted_rowval.data(),            // innerIndexPtr (row indices)
    const_cast<double*>(x_vals.data()) // valuePtr (non-zero values)
  );
}

slope::Slope
setupModel(bool fit_intercept,
           std::string loss_type,
           std::string centering_type,
           std::string scaling_type,
           std::int64_t path_length,
           double tol,
           std::int64_t max_it,
           double q,
           std::int64_t max_clusters,
           double dev_change_tol,
           double dev_ratio_tol,
           double alpha_min_ratio)
{
  slope::Slope model;

  model.setCentering(centering_type);
  model.setAlphaMinRatio(alpha_min_ratio);
  model.setDevChangeTol(dev_change_tol);
  model.setDevRatioTol(dev_ratio_tol);
  model.setIntercept(fit_intercept);
  model.setLoss(loss_type);
  model.setMaxClusters(max_clusters);
  model.setMaxIterations(max_it);
  model.setPathLength(path_length);
  model.setQ(q);
  model.setScaling(scaling_type);
  model.setTol(tol);

  return model;
}

void
returnOutput(const slope::SlopePath& res,
             jlcxx::ArrayRef<double, 1> coef_vals_out,
             jlcxx::ArrayRef<std::int64_t, 1> coef_rows_out,
             jlcxx::ArrayRef<std::int64_t, 1> coef_cols_out,
             jlcxx::ArrayRef<double, 1> intercepts_out,
             jlcxx::ArrayRef<std::int64_t, 1> nnz_out,
             jlcxx::ArrayRef<double, 1> alpha_out,
             jlcxx::ArrayRef<double, 1> lambda_out)
{
  auto coefs = res.getCoefs();
  auto intercepts = res.getIntercepts();
  Eigen::ArrayXd alpha = res.getAlpha();
  Eigen::ArrayXd lambda = res.getLambda();

  for (const auto& l : lambda) {
    lambda_out.push_back(l);
  }

  int nnz = 0;

  for (int step = 0; step < coefs.size(); ++step) {
    Eigen::SparseMatrix<double> coefs_step = coefs[step];

    for (int k = 0; k < coefs_step.outerSize(); ++k) {
      for (Eigen::SparseMatrix<double>::InnerIterator it(coefs_step, k); it;
           ++it) {
        coef_vals_out.push_back(it.value());
        coef_rows_out.push_back(it.row() + 1);
        coef_cols_out.push_back(k + 1);
        nnz++;
      }
      intercepts_out.push_back(intercepts[step](k));
    }
    nnz_out.push_back(nnz);

    alpha_out.push_back(alpha[step]);
  }
}

std::vector<std::vector<std::vector<int>>>
createCvFolds(const std::vector<std::int64_t>& fold_indices,
              std::int64_t n,
              std::int64_t n_folds,
              std::int64_t n_repeats)
{
  // Create the nested fold structure: repeats → folds → indices
  std::vector<std::vector<std::vector<int>>> folds(n_repeats);

  // Calculate fold sizes: how many observations per fold
  std::vector<int> fold_sizes(n_folds, n / n_folds);
  for (int i = 0; i < n % n_folds; ++i) {
    fold_sizes[i]++; // Distribute remainder among first folds
  }

  // Process the flat fold indices into the nested structure
  int index_pos = 0;
  for (int r = 0; r < n_repeats; ++r) {
    folds[r].resize(n_folds);

    // First, collect all indices for this repeat
    std::vector<int> repeat_indices(n);
    for (int i = 0; i < n; ++i) {
      repeat_indices[i] =
        fold_indices[index_pos++] - 1; // Convert 1-indexed to 0-indexed
    }

    // Then distribute indices into folds
    int start_idx = 0;

    for (int f = 0; f < n_folds; ++f) {
      folds[r][f].resize(fold_sizes[f]);

      for (int i = 0; i < fold_sizes[f]; ++i) {
        folds[r][f][i] = repeat_indices[start_idx + i];
      }

      start_idx += fold_sizes[f];
    }
  }

  return folds;
}
