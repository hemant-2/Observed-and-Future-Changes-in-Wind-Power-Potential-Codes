import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import pearsonr

BASE_DIR = "/data/MUKESH/Docs/Project_hydrology/Power_energy" # change to your path
WIND_COL, DPI = "Mean_Annual_WindSpeed", 300


OUT_DIR = os.path.join(BASE_DIR, "Combined_Figures")
os.makedirs(OUT_DIR, exist_ok=True)

REGIONS = [
    {"name": "Western_India", "title": "Western India", "drivers": ["TNA", "AO"]},
    {"name": "South_india", "title": "South India", "drivers": ["TNA", "NAO"]},
]

OBS_COLOR, PRED_COLOR = "#1f4e8c", "#c1440e"

LABELS = ["(a)", "(b)", "(c)", "(d)"]

plt.rcParams.update({"font.family": "DejaVu Serif", "font.size": 11, "axes.linewidth": 1.0, "axes.edgecolor": "black"})

def fit_and_predict(region):
    path = os.path.join(BASE_DIR, region["name"], "Processed_Data", "Wind", "Annual_Wind_1951_2025.csv")
    drivers = region["drivers"]
    data = (pd.read_csv(path)[["Year", WIND_COL] + drivers]
            .dropna().sort_values("Year").reset_index(drop=True))

    obs = data[WIND_COL].values
    X = np.column_stack([data[d].values for d in drivers] + [np.ones(len(data))])
    coeffs = np.linalg.lstsq(X, obs, rcond=None)[0]
    pred = X @ coeffs

    r2 = 1 - np.sum((obs - pred) ** 2) / np.sum((obs - obs.mean()) ** 2)
    rmse = np.sqrt(np.mean((obs - pred) ** 2))
    r = pearsonr(obs, pred)[0]

    # Equation string, e.g. W_pred = -0.123(TNA) + 0.045(AO) + 3.210
    terms = [f"{coeffs[0]:.3f}({drivers[0]})"]
    terms += [f"{'+' if c >= 0 else '-'} {abs(c):.3f}({d})" for c, d in zip(coeffs[1:-1], drivers[1:])]
    eq = "W$_{pred}$ = " + " ".join(terms) + f" {'+' if coeffs[-1] >= 0 else '-'} {abs(coeffs[-1]):.3f}"

    print(f"{region['title']}: {eq}\n R2={r2:.4f} RMSE={rmse:.4f} r={r:.4f} N={len(data)}")
    return {"years": data["Year"].values, "obs": obs, "pred": pred, "r": r, "eq": eq}

def label_panel(ax, text):
    ax.text(0.02, 0.95, text, transform=ax.transAxes, fontsize=12,

            fontweight="bold", va="top", ha="left")

def plot_timeseries(ax, region, res, label):
    ax.plot(res["years"], res["obs"], color=OBS_COLOR, lw=1.8, marker="o", ms=3, label="Observed Wind Speed")
    ax.plot(res["years"], res["pred"], color=PRED_COLOR, lw=1.8, marker="s", ms=3, label="Predicted Wind Speed")
    ax.set(xlabel="Year", ylabel="Wind Speed (m/s)")
    label_panel(ax, label)
    ax.legend(loc="upper right", frameon=False, fontsize=9)
    ax.text(0.5, 0.06, f"{region['title']} (r = {res['r']:.3f})\n{res['eq']}",
            transform=ax.transAxes, fontsize=10, fontweight="bold", va="center", ha="center")

def plot_scatter(ax, region, res, label):
    obs, pred = res["obs"], res["pred"]
    lims = [min(obs.min(), pred.min()), max(obs.max(), pred.max())]
    ax.scatter(obs, pred, color=OBS_COLOR, edgecolor="black", s=45, alpha=0.9, zorder=3)
    ax.plot(lims, lims, "r--", lw=1.5, zorder=2) # 1:1 line
    ax.set(xlim=lims, ylim=lims, xlabel="Observed Wind Speed (m/s)", ylabel="Predicted Wind Speed (m/s)")

    ax.set_aspect("equal", adjustable="box")
    label_panel(ax, label)
    ax.text(0.95, 0.05, region["title"], transform=ax.transAxes, fontsize=12,

            fontweight="bold", va="bottom", ha="right")

results = [fit_and_predict(r) for r in REGIONS]

fig, axes = plt.subplots(2, 2, figsize=(13, 10))

for row, (region, res) in enumerate(zip(REGIONS, results)):
    plot_timeseries(axes[row][0], region, res, LABELS[2 * row])
    plot_scatter(axes[row][1], region, res, LABELS[2 * row + 1])

fig.tight_layout()
plt.savefig(os.path.join(OUT_DIR, "Time_Series_Annual_Wind_Speed.png"), dpi=DPI, bbox_inches="tight")
plt.show()