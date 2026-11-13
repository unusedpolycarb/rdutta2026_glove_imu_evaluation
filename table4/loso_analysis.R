setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

set.seed(42)
B <- 10000
metrics <- read.csv(file.path('../table3/per_pitcher_metrics.csv'))
models <- c('z_threshold', 'knn', 'logistic')
metric_names <- c('sensitivity','specificity','precision','FPR','balanced_accuracy','accuracy', 'f1')

# Group summaries (n = 9 pitchers per domain and classifier)
summary_rows <- list()
for (model in models) for (domain in c('time', 'frequency')) {
  d <- metrics[metrics$model == model & metrics$domain == domain, ]
  for (measure in metric_names) {
    vals <- d[[measure]]
    summary_rows[[length(summary_rows) + 1]] <- data.frame(
      model = model, domain = domain, metric = measure,
      n_pitchers = sum(is.finite(vals)),
      mean = mean(vals, na.rm = TRUE), sd = sd(vals, na.rm = TRUE),
      min = min(vals, na.rm = TRUE), max = max(vals, na.rm = TRUE))
  }
}
summary_table <- do.call(rbind, summary_rows)
write.csv(summary_table, file.path('subject_level_summary.csv'), row.names = FALSE)
table4_metrics <- c('sensitivity', 'specificity', 'precision',
                    'accuracy', 'balanced_accuracy', 'f1')

table4 <- summary_table[
  summary_table$metric %in% table4_metrics,
  c('model', 'domain', 'metric', 'mean')
]

table4 <- reshape(
  table4,
  idvar = c('model', 'domain'),
  timevar = 'metric',
  direction = 'wide'
)

names(table4) <- sub('mean.', '', names(table4), fixed = TRUE)

table4 <- table4[
  , c('model', 'domain', table4_metrics)
]

names(table4) <- c(
  'Model', 'Domain', 'TPR', 'TNR',
  'Precision', 'Accuracy', 'BA', 'F1'
)

table4 <- table4[
  order(match(table4$Model, models),
        match(table4$Domain, c('time', 'frequency'))),
]

write.csv(
  table4,
  file.path('table4_mean_classification_performance.csv'),
  row.names = FALSE
)

