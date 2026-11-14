setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
set.seed(42)
B_mean <- 10000
B_sd <- 100000

metrics <- read.csv(file.path('../table3/per_pitcher_metrics.csv'))
models <- c('z_threshold', 'knn', 'logistic')
metric_names <- c('sensitivity', 'specificity', 'precision', 'accuracy', 'balanced_accuracy', 'f1')

# Exact two-sided paired sign-flip permutation test
exact_paired_p <- function(d) {
  n <- length(d)
  signs <- as.matrix(expand.grid(rep(list(c(-1, 1)), n)))
  possible <- as.vector(signs %*% d / n)
  mean(abs(possible) >= abs(mean(d)) - 1e-12)
}

# Bootstrap helper functions
resample_indices <- function(n, B) {
  matrix(sample.int(n, B * n, replace = TRUE), nrow = B, ncol = n)
}

row_sample_sd <- function(x) {
  n <- ncol(x)
  mu <- rowMeans(x)
  sqrt(pmax(0, (rowSums(x * x) - n * mu^2) / (n - 1)))
}

percentile_ci <- function(x) {
  unname(quantile(x, c(.025, .975)))
}

# Paired domain comparisons (n = 9 pitchers per classifier)
mean_rows <- list()
paired_rows <- list()
sd_rows <- list()
paired_subject_rows <- list()

for (model in models) {
  d <- metrics[metrics$model == model, ]
  time <- d[d$domain == 'time', ]
  freq <- d[d$domain == 'frequency', ]
  time <- time[order(time$pitcher), ]
  freq <- freq[order(freq$pitcher), ]
  
  stopifnot(
    nrow(time) == 9,
    nrow(freq) == 9,
    identical(as.character(time$pitcher), as.character(freq$pitcher))
  )
  
  # Resample PITCHERS jointly so domain pairing is preserved.
  ids_mean <- resample_indices(nrow(time), B_mean)
  ids_sd <- resample_indices(nrow(time), B_sd)
  
  for (measure in metric_names) {
    tvals <- time[[measure]]
    fvals <- freq[[measure]]
    stopifnot(all(is.finite(tvals)), all(is.finite(fvals)))
    
    dif <- fvals - tvals
    
    # Bootstrap 95% CIs for domain means and paired mean differences
    boot_time <- rowMeans(matrix(tvals[ids_mean], nrow = B_mean))
    boot_freq <- rowMeans(matrix(fvals[ids_mean], nrow = B_mean))
    boot_mean <- rowMeans(matrix(dif[ids_mean], nrow = B_mean))
    
    ci_time <- percentile_ci(boot_time)
    ci_freq <- percentile_ci(boot_freq)
    ci_mean <- percentile_ci(boot_mean)
    
    # Bootstrap 95% CI for difference in inter-pitcher SD
    boot_time_sd <- matrix(tvals[ids_sd], nrow = B_sd)
    boot_freq_sd <- matrix(fvals[ids_sd], nrow = B_sd)
    boot_sd_difference <- row_sample_sd(boot_freq_sd) -
      row_sample_sd(boot_time_sd)
    
    ci_sd <- percentile_ci(boot_sd_difference)
    
    mean_rows[[length(mean_rows) + 1]] <- data.frame(
      model = model, metric = measure,
      mean_time = mean(tvals), time_95CI_low = ci_time[1],
      time_95CI_high = ci_time[2],
      mean_frequency = mean(fvals), frequency_95CI_low = ci_freq[1],
      frequency_95CI_high = ci_freq[2]
    )
    
    paired_rows[[length(paired_rows) + 1]] <- data.frame(
      model = model, metric = measure, n_pitchers = length(dif),
      mean_paired_difference_freq_minus_time = mean(dif),
      paired_difference_95CI_low = ci_mean[1],
      paired_difference_95CI_high = ci_mean[2],
      exact_permutation_p = exact_paired_p(dif),
      CI95_excludes_zero = (ci_mean[1] > 0 || ci_mean[2] < 0)
    )
    
    sd_rows[[length(sd_rows) + 1]] <- data.frame(
      model = model, metric = measure,
      sd_time = sd(tvals), sd_frequency = sd(fvals),
      sd_difference_freq_minus_time = sd(fvals) - sd(tvals),
      sd_difference_95CI_low = ci_sd[1],
      sd_difference_95CI_high = ci_sd[2],
      CI95_excludes_zero = (ci_sd[1] > 0 || ci_sd[2] < 0)
    )
    
    paired_subject_rows[[length(paired_subject_rows) + 1]] <- data.frame(
      model = model, metric = measure, pitcher = time$pitcher,
      time = tvals, frequency = fvals,
      difference_freq_minus_time = dif
    )
  }
}

mean_results <- do.call(rbind, mean_rows)
paired_results <- do.call(rbind, paired_rows)
sd_results <- do.call(rbind, sd_rows)
paired_subjects <- do.call(rbind, paired_subject_rows)

write.csv(mean_results, file.path('../table4/table4_domain_means_CIs.csv'), row.names = FALSE)
write.csv(paired_results, file.path('table5_paired_metric_tests.csv'), row.names = FALSE)
write.csv(sd_results, file.path('../table6/table6_inter_pitcher_SD.csv'), row.names = FALSE)

paired_subjects <- merge(
  paired_subjects,
  paired_results[, c("model", "metric", "exact_permutation_p")],
  by = c("model", "metric"),
  sort = FALSE
)

write.csv(
  paired_subjects,
  '../figure6/per_pitcher_paired_metrics.csv',
  row.names = FALSE
)

