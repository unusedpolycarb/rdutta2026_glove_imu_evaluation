from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat
from imblearn.over_sampling import SMOTE
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import confusion_matrix

HERE = Path(__file__).resolve().parent
print(HERE)
DATA_DIR = (HERE / "../data/classifier data").resolve()  # EDIT: frequency feature CSV folder
MAT_FILE = (HERE / "../data/matlab DATA files/processed_pitch_data.mat").resolve()

PITCH_COUNTS = [10] * 9
NONPITCH_COUNTS = [518, 222, 336, 587, 449, 358, 256, 126, 114]
P5 = 5
FS = 200

def read_feature_csv(name, counts):
    x = pd.read_csv(DATA_DIR / name, header=None).to_numpy(dtype=float).T
    participant = np.repeat(np.arange(1, 10), counts)
    if x.shape[0] != len(participant):
        raise ValueError(f"{name}: {x.shape[0]} observations, expected {len(participant)}")
    return x, participant

xp, sp = read_feature_csv("all_pitch_freq_domain.csv", PITCH_COUNTS)
xn, sn = read_feature_csv("all_non_pitch_freq_domain.csv", NONPITCH_COUNTS)
X = np.vstack((xn, xp))
y = np.r_[np.zeros(len(xn), dtype=int), np.ones(len(xp), dtype=int)]
subjects = np.r_[sn, sp]

train = subjects != P5
test = subjects == P5

Xsm, ysm = SMOTE(sampling_strategy="minority", random_state=42).fit_resample(X[train], y[train])
scaler = StandardScaler().fit(Xsm)
clf = LogisticRegression(C=1.0, l1_ratio=0.0, solver="lbfgs",
                         max_iter=5000, tol=1e-4, random_state=29)
clf.fit(scaler.transform(Xsm), ysm)
pred = clf.predict(scaler.transform(X[test])).astype(int)
truth = y[test].astype(int)

TN, FP, FN, TP = confusion_matrix(truth, pred, labels=[0, 1]).ravel()
print(f"P5: TP={TP}, FP={FP}, TN={TN}, FN={FN}")
if (TP, FP, TN, FN) != (9, 16, 433, 1):
    raise RuntimeError("P5 confusion counts differ from expected (9,16,433,1). "
                       "Verify the input features and full training pipeline.")

mat = loadmat(MAT_FILE)
pitch_waves = np.asarray(mat["total_pitch_accel_data"][P5 - 1, 0], dtype=float)
nonpitch_waves = np.asarray(mat["total_non_pitch_accel_data"][P5 - 1, 0], dtype=float)

n_np = NONPITCH_COUNTS[P5 - 1]
class_names = np.where(truth == 1, "pitch", "nonpitch")
window_idx = np.where(truth == 1, np.arange(len(truth)) - n_np + 1,
                      np.arange(len(truth)) + 1)
outcomes = np.select(
    [(truth == 1) & (pred == 1), (truth == 0) & (pred == 1),
     (truth == 0) & (pred == 0), (truth == 1) & (pred == 0)],
    ["TP", "FP", "TN", "FN"], default="UNKNOWN")

waves = np.column_stack([nonpitch_waves, pitch_waves])
results = pd.DataFrame({
    "pitcher": "P5",
    "test_index_1based": np.arange(1, len(truth) + 1),
    "source_class": class_names,
    "source_window_1based": window_idx,
    "true_label": truth,
    "predicted_label": pred,
    "outcome": outcomes,
    "peak_accel_g": np.nanmax(waves, axis=0),
    "mean_accel_g": np.nanmean(waves, axis=0),
})

savemat("p5_all_outcomes.mat", {
    "waveforms": waves,
    "time_s": np.arange(300, dtype=float).reshape(-1, 1) / FS,
    "test_index_1based": np.arange(1, len(truth) + 1, dtype=np.int32).reshape(-1, 1),
    "source_window_1based": window_idx.astype(np.int32).reshape(-1, 1),
    "true_label": truth.astype(np.int32).reshape(-1, 1),
    "predicted_label": pred.astype(np.int32).reshape(-1, 1),
    "outcome": np.asarray(outcomes, dtype="U2").reshape(-1, 1),
    "TP_indices": np.flatnonzero(outcomes == "TP").astype(np.int32).reshape(-1, 1) + 1,
    "FP_indices": np.flatnonzero(outcomes == "FP").astype(np.int32).reshape(-1, 1) + 1,
    "TN_indices": np.flatnonzero(outcomes == "TN").astype(np.int32).reshape(-1, 1) + 1,
    "FN_indices": np.flatnonzero(outcomes == "FN").astype(np.int32).reshape(-1, 1) + 1,
})
