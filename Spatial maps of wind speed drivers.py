import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import matplotlib.ticker as mticker
from matplotlib.path import Path as MplPath
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from cartopy.io import shapereader

BASE_DIR = "/data/MUKESH/Docs/Project_hydrology/Power_energy" # change to your path
PERIOD, SEASON = "1951_2025", "Annual"
PAD, DPI = 0.30, 600

OUT_DIR = os.path.join(BASE_DIR, "Combined_Figures")
os.makedirs(OUT_DIR, exist_ok=True)
OUTPUT = os.path.join(OUT_DIR, "Figure4_Dominant_Drivers_Western_South_India_1951_2025.png")


CONFIG = [
    {"region": "Western_India", "boundary": "box_1_coords.txt",
     "subdir": "spatial_analysis_2", "indices": [("TNA", "neg"), ("AO", "neg")]},

    {"region": "South_india", "boundary": "box_2_coords.txt",
     "subdir": "spatial_analysis", "indices": [("TNA", "neg"), ("NAO", "pos")]},
]

SCHEMES = {
"neg": ("YlOrRd_r", mcolors.Normalize(-0.65, 0.0), np.arange(-0.6, 0.01, 0.1)), "pos": ("Blues", mcolors.Normalize(0.0, 0.35), np.arange(0.0, 0.36, 0.05)),
}

PANELS = [[0.07, 0.535, 0.36, 0.40], [0.57, 0.535, 0.36, 0.40], [0.04, 0.055, 0.42, 0.42], [0.54, 0.055, 0.42, 0.42]]
CBARS = [[0.435, 0.555, 0.018, 0.36], [0.935, 0.555, 0.018, 0.36], [0.435, 0.075, 0.018, 0.36], [0.935, 0.075, 0.018, 0.36]]


plt.rcParams.update({"font.family": "DejaVu Serif", "font.size": 10, "axes.linewidth": 1.0})

def load_india():
    shp = shapereader.natural_earth("10m", "cultural", "admin_0_countries")
    for rec in shapereader.Reader(shp).records():
        if rec.attributes["NAME_LONG"] == "India":
            return rec.geometry

    raise RuntimeError("India boundary could not be loaded.")

def load_boundary(path):
    df = pd.read_csv(path, header=None, names=["Lat", "Lon"])
    poly = list(zip(df["Lon"], df["Lat"]))
    poly.append(poly[0]) # close polygon
    extent = [df["Lon"].min() - PAD, df["Lon"].max() + PAD,
              df["Lat"].min() - PAD, df["Lat"].max() + PAD]
    return df, MplPath(poly), extent

def draw_basemap(ax, bdf, bpath, extent, india):
    pc = ccrs.PlateCarree()
    ax.set_extent(extent, crs=pc)
    ax.set_boundary(bpath, transform=pc)

    ax.add_feature(cfeature.LAND, facecolor="white", edgecolor="none", zorder=0)
    ax.add_feature(cfeature.OCEAN, facecolor="white", edgecolor="none", zorder=0)
    ax.add_geometries([india], pc, facecolor="none", edgecolor="black", linewidth=0.8, zorder=6)
    ax.plot(bdf["Lon"], bdf["Lat"], color="black", linewidth=1.2, transform=pc, zorder=20)

    try:
        ax.spines["geo"].set_visible(False)
    except Exception:
        pass

def plot_corr(ax, df, bdf, bpath, extent, india, cmap, norm):
    draw_basemap(ax, bdf, bpath, extent, india)

    ax.set_aspect("equal", adjustable="box")
    lat_c = next(c for c in df.columns if c.lower() == "lat")
    lon_c = next(c for c in df.columns if c.lower() == "lon")
    lats, lons = np.sort(df[lat_c].unique()), np.sort(df[lon_c].unique())

    Lon, Lat = np.meshgrid(lons, lats)

    corr = (df.pivot(index=lat_c, columns=lon_c, values="Correlation")
              .reindex(index=lats, columns=lons).values)
    inside = bpath.contains_points(np.c_[Lon.ravel(), Lat.ravel()]).reshape(Lon.shape)

    corr = np.where(inside, corr, np.nan)

    return ax.pcolormesh(Lon, Lat, corr, cmap=cmap, norm=norm, shading="auto",
                         transform=ccrs.PlateCarree(), zorder=2)

def add_gridlabels(ax):
    gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True, linewidth=0)
    gl.top_labels = gl.right_labels = False
    fmt = mticker.FuncFormatter(lambda v, _: f"{v:.1f}")
    gl.xformatter = gl.yformatter = fmt
    gl.xlocator = gl.ylocator = mticker.MaxNLocator(5)
    gl.xlabel_style = gl.ylabel_style = {"size": 9}

india = load_india()

fig = plt.figure(figsize=(12, 8.2), facecolor="white")
n = 0 # panel counter

for region in CONFIG:
    bdf, bpath, extent = load_boundary(os.path.join(BASE_DIR, region["region"], region["boundary"]))
    corr_dir = os.path.join(BASE_DIR, region["region"], region["subdir"],
                            "Correlation_CSV", PERIOD, SEASON)

    for index, scheme in region["indices"]:
        csv = os.path.join(corr_dir, f"{index}_Correlation.csv")
        if not os.path.exists(csv): # skip missing files but keep panel numbering
            n += 1
            continue

        cmap, norm, ticks = SCHEMES[scheme]
        ax = fig.add_axes(PANELS[n], projection=ccrs.PlateCarree())
        mesh = plot_corr(ax, pd.read_csv(csv), bdf, bpath, extent, india, cmap, norm)
        add_gridlabels(ax)
        ax.set_title(f"({'abcd'[n]}) {index}", fontsize=12, pad=6)

        cbar = fig.colorbar(mesh, cax=fig.add_axes(CBARS[n]), extend="both")

        cbar.set_ticks(ticks)
        cbar.set_label("Correlation", fontsize=10)
        cbar.ax.tick_params(labelsize=9)
        n += 1

plt.savefig(OUTPUT, dpi=DPI, bbox_inches="tight", facecolor="white")
plt.show()