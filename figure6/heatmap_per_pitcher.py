
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import Normalize, LinearSegmentedColormap

DATA_DIR = Path(__file__).resolve().parent.parent

df = pd.read_csv("per_pitcher_paired_metrics.csv")

models = ["z_threshold", "knn", "logistic"]
metrics = ["sensitivity", "specificity", "precision",
           "accuracy", "balanced_accuracy", "f1"]

model_labels = ["Z-threshold", "k-NN", "Logistic regression"]
metric_labels = ["TPR", "TNR", "Precision", "Accuracy", "BA", "F1"]
pitchers = [f"P{i}" for i in range(1, 10)]

df["pitcher"] = df["pitcher"].astype(str)
df["pitcher"] = df["pitcher"].apply(
    lambda x: x if x.startswith("P") else f"P{x}"
)

pvalues = {}

for (model, metric), group in df.groupby(["model", "metric"]):

    p = group["exact_permutation_p"].to_numpy()

    if not np.allclose(p, p[0]):
        raise ValueError(
            f"Inconsistent p-values for {model}, {metric}"
        )

    pvalues[(model, metric)] = p[0]

heat = LinearSegmentedColormap.from_list(
    "heat",
    ["#FFFFFF", "#FFE5A3", "#FFAF45", "#E85A2A", "#8B0000"]
)

vmin = df["difference_freq_minus_time"].min()
vmax = df["difference_freq_minus_time"].max()
norm = Normalize(vmin=vmin, vmax=vmax)

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

fig, axes = plt.subplots(
    3, 1,
    figsize=(11.5, 18),
    gridspec_kw={"hspace": 0.35}
)

for ax, model, label in zip(axes, models, model_labels):

    d = df[df["model"] == model]

    pivot = d.pivot(
        index="pitcher",
        columns="metric",
        values="difference_freq_minus_time"
    ).loc[pitchers, metrics]

    values = pivot.to_numpy()

    im = ax.imshow(
        values,
        cmap=heat,
        norm=norm,
        aspect="auto"
    )

    labels = []

    for metric, metric_label in zip(metrics, metric_labels):

        p = pvalues[(model, metric)]

        if p < 0.05:
            labels.append(metric_label + "*")
        else:
            labels.append(metric_label)

    ax.set_xticks(range(len(metrics)), labels)
    ax.set_yticks(range(len(pitchers)), pitchers)

    # Bold labels for significant comparisons
    for j, tick_label in enumerate(ax.get_xticklabels()):

        metric = metrics[j]
        p = pvalues[(model, metric)]

        if p < 0.05:
            tick_label.set_fontweight("bold")

    ax.set_xlabel("Classification metric")
    ax.set_ylabel("Held-out pitcher")
    ax.set_title(label, fontsize=15, pad=12)

    for i in range(len(pitchers)):
        for j in range(len(metrics)):

            rgba = heat(norm(values[i, j]))
            r, g, b = rgba[:3]

            brightness = (
                0.299*r + 0.587*g + 0.114*b
            )

            text_color = (
                "black" if brightness > 0.55 else "white"
            )

            ax.text(
                j, i,
                f"{values[i, j]:+.3f}",
                ha="center",
                va="center",
                fontsize=10,
                color=text_color
            )

fig.suptitle(
    "Per-pitcher paired performance differences (Frequency - Time)",
    fontsize=17,
    y=0.98
)

cbar = fig.colorbar(
    im,
    ax=axes,
    orientation="vertical",
    fraction=0.025,
    pad=0.04,
    shrink=0.75,
    aspect=35
)

cbar.set_label(
    "Paired performance difference",
    fontsize=12
)


fig.savefig(
    "figure6.png",
    dpi=600,
    bbox_inches="tight",
    facecolor="white"
)

plt.show()
