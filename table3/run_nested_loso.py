import numpy as np
import pandas as pd
from pathlib import Path
from pitch_classifier_eval import make_domain, fit_predict, metrics, K_VALUES, Z_VALUES

OUTPUT_DIR = Path(__file__).resolve().parent.parent / 'table3'
BOOTSTRAP_REPS = 10000
rng = np.random.default_rng(42)

rows, selections, predictions = [], [], []
for domain in ('time', 'frequency'):
    X, y, subjects = make_domain(domain)
    for model in ('z_threshold', 'knn', 'logistic'):
        for test_pitcher in range(1, 10):
            outer_train = subjects != test_pitcher
            outer_test = ~outer_train
            if model == 'logistic':
                best_parameter = None  # fixed parameters; no tuning needed
            else:
                candidates = Z_VALUES if model == 'z_threshold' else K_VALUES
                average_scores = []
                for parameter in candidates:
                    scores = []
                    for val_pitcher in range(1, 10):
                        if val_pitcher == test_pitcher:
                            continue
                        inner_train = outer_train & (subjects != val_pitcher)
                        inner_val = subjects == val_pitcher
                        pred = fit_predict(model, parameter, X[inner_train], y[inner_train], X[inner_val])
                        scores.append(metrics(y[inner_val], pred)['balanced_accuracy'])
                    average_scores.append(np.mean(scores))
                # np.argmax breaks ties by using the first (smallest) candidate.
                best_parameter = candidates[int(np.argmax(average_scores))]

            pred = fit_predict(model, best_parameter, X[outer_train], y[outer_train], X[outer_test])
            result = metrics(y[outer_test], pred)
            rows.append({'domain': domain, 'model': model, 'pitcher': test_pitcher,
                         'parameter': best_parameter, **result})
            selections.append({'domain': domain, 'model': model, 'pitcher': test_pitcher,
                               'selected_parameter': best_parameter})
            indices = np.flatnonzero(outer_test)
            predictions.extend({'domain': domain, 'model': model, 'pitcher': test_pitcher,
                                'sample_index': int(idx), 'actual': int(y[idx]), 'predicted': int(p)}
                               for idx, p in zip(indices, pred))
            print(f'{domain:9s} {model:12s} P{test_pitcher}: BA={result["balanced_accuracy"]:.3f}, parameter={best_parameter}')

results = pd.DataFrame(rows)
summary_rows = []
for (domain, model), group in results.groupby(['domain', 'model'], sort=False):
    entry = {'domain': domain, 'model': model}
    for metric in ('sensitivity', 'specificity', 'precision', 'FPR', 'balanced_accuracy', 'accuracy'):
        values = group[metric].to_numpy(float)
        entry[f'{metric}_mean'] = np.nanmean(values)
        entry[f'{metric}_sd'] = np.nanstd(values, ddof=1)
        # Resample pitchers (not individual windows). Undefined precision stays missing.
        samples = values[rng.integers(0, len(values), (BOOTSTRAP_REPS, len(values)))]
        valid = np.sum(np.isfinite(samples), axis=1)
        boot_means = np.divide(np.nansum(samples, axis=1), valid,
                               out=np.full(BOOTSTRAP_REPS, np.nan), where=valid > 0)
        if np.isfinite(boot_means).any():
            entry[f'{metric}_ci_low'], entry[f'{metric}_ci_high'] = np.nanpercentile(boot_means, [2.5, 97.5])
        else:
            entry[f'{metric}_ci_low'] = entry[f'{metric}_ci_high'] = np.nan
    summary_rows.append(entry)

OUTPUT_DIR.mkdir(exist_ok=True)
results.to_csv(OUTPUT_DIR / 'per_pitcher_metrics.csv', index=False)
print('\nSaved results to:', OUTPUT_DIR)
