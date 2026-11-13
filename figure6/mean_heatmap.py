
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import TwoSlopeNorm, LinearSegmentedColormap

DATA_DIR = Path(__file__).resolve().parent.parent

df = pd.read_csv(
    DATA_DIR / "table5" / "table5_paired_metric_tests.csv"
)

models = ["z_threshold", "knn", "logistic"]
metrics = ["sensitivity", "specificity", "precision",
           "accuracy", "balanced_accuracy", "f1"]

model_labels = ["Z-threshold", "k-NN", "Logistic regression"]
metric_labels = ["TPR", "TNR", "Precision", "Accuracy", "BA", "F1"]

pivot = df.pivot(
    index="model",
    columns="metric",
    values="mean_paired_difference_freq_minus_time"
).loc[models, metrics]

values = pivot.to_numpy()

limit = np.max(np.abs(values))
norm = TwoSlopeNorm(vmin=-limit, vcenter=0, vmax=limit)

heat = LinearSegmentedColormap.from_list(
    "heat",
    ["#FFFFFF", "#FFE5A3", "#FFAF45", "#E85A2A", "#8B0000"]
)

plt.rcParams.update({
    "font.family": "serif",
    "font.serif": ["Times New Roman"],
    "text.color": "black",
    "axes.labelcolor": "black",
    "axes.edgecolor": "black",
    "xtick.color": "black",
    "ytick.color": "black",
    "figure.facecolor": "white",
    "axes.facecolor": "white"
})

fig, ax = plt.subplots(figsize=(11, 4.5))

im = ax.imshow(values, cmap=heat, aspect="auto")

ax.set_xticks(range(len(metrics)), metric_labels)
ax.set_yticks(range(len(models)), model_labels)

ax.set_xlabel("Classification metric")
ax.set_ylabel("Classifier")
ax.set_title(
    "Mean paired performance differences (Frequency - Time)",
    pad=15
)

for i in range(len(models)):
    for j in range(len(metrics)):
        r, g, b, _ = heat(
            (values[i, j] - values.min()) /
            (values.max() - values.min())
        )

        brightness = 0.299*r + 0.587*g + 0.114*b
        text_color = "black" if brightness > 0.55 else "white"

        ax.text(
            j, i, f"{values[i, j]:+.4f}",
            ha="center", va="center",
            fontsize=10, color=text_color
        )

cbar = fig.colorbar(im, ax=ax, shrink=0.85, pad=0.02)
cbar.set_label("Mean paired difference")

fig.tight_layout()

fig.savefig(
    "figure6.png",
    dpi=600,
    bbox_inches="tight",
    facecolor="white"
)

plt.show()
