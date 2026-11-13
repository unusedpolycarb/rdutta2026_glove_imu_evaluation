from pathlib import Path
import numpy as np
import pandas as pd
from imblearn.over_sampling import SMOTE
from sklearn.neighbors import KNeighborsClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import confusion_matrix

DATA_DIR = Path(__file__).resolve().parent.parent
FILES = {
    'time': {'pitch': 'data/classifier data/all_pitch_time_domain_features.csv', 'nonpitch': 'data/classifier data/all_non_pitch_time_domain_features.csv'},
    'frequency': {'pitch': 'data/classifier data/all_pitch_freq_domain.csv', 'nonpitch': 'data/classifier data/all_non_pitch_freq_domain.csv'},
}
PITCH_COUNTS = [10] * 9
NONPITCH_COUNTS = [518, 222, 336, 587, 449, 358, 256, 126, 114]
K_VALUES = list(range(5, 51, 5))
Z_VALUES = np.arange(0.25, 3.01, 0.25)
RANDOM_SEED = 42

def load_features(filename, counts):
    X = pd.read_csv(DATA_DIR / filename, header=None).to_numpy(dtype=float).T
    subjects = np.repeat(np.arange(1, 10), counts)
    return X, subjects

def make_domain(domain):
    xp, sp = load_features(FILES[domain]['pitch'], PITCH_COUNTS)
    xn, sn = load_features(FILES[domain]['nonpitch'], NONPITCH_COUNTS)
    X = np.vstack((xn, xp))
    y = np.r_[np.zeros(len(xn)), np.ones(len(xp))].astype(int)
    subjects = np.r_[sn, sp]
    return X, y, subjects

def balance(X, y):
    return SMOTE(sampling_strategy='minority', random_state=RANDOM_SEED).fit_resample(X, y)

def fit_predict(model, parameter, Xtr, ytr, Xev):
    Xsm, ysm = balance(Xtr, ytr)
    if model == 'z_threshold':
        pitch_train = Xsm[ysm == 1]
        mu = pitch_train.mean(axis=0)
        sigma = pitch_train.std(axis=0, ddof=0)
        sigma[sigma == 0] = 1e-8
        scores = np.mean(np.abs((Xev - mu) / sigma), axis=1)
        return (scores <= parameter).astype(int)
    scaler = StandardScaler().fit(Xsm)
    xfit = scaler.transform(Xsm)
    xval = scaler.transform(Xev)
    if model == 'knn':
        clf = KNeighborsClassifier(n_neighbors=int(parameter), weights='uniform', metric='minkowski', p=2)
    elif model == 'logistic':
        clf = LogisticRegression(C=1.0, solver='lbfgs', max_iter=5000, tol=1e-4, random_state=29)
    else:
        raise ValueError(model)
    clf.fit(xfit, ysm)
    return clf.predict(xval)

def metrics(y, pred):
    tn, fp, fn, tp = confusion_matrix(y, pred, labels=[0, 1]).ravel()
    sensitivity = tp/(tp+fn) if tp+fn else np.nan
    specificity = tn/(tn+fp) if tn+fp else np.nan
    precision = tp/(tp+fp) if tp+fp else np.nan

    return dict(
        TN=tn, FP=fp, FN=fn, TP=tp,
        sensitivity=sensitivity,
        specificity=specificity,
        precision=precision,
        FPR=1-specificity,
        balanced_accuracy=(sensitivity+specificity)/2,
        accuracy=(tp+tn)/(tp+tn+fp+fn),
        f1=2*tp/(2*tp+fp+fn)
    )
