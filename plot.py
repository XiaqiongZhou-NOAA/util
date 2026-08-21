#!/usr/bin/env python3
import os
import numpy as np
import pandas as pd
import xarray as xr
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
from matplotlib.ticker import MaxNLocator

# 1. Import your configuration file directly
import config

# ======================================================================
# 2. Configuration Setup (Directly from config.py)
# ======================================================================
DATAOUT = config.DATAOUT
ANADATADIR = config.ANADATADIR

EXPLIST = config.EXPLIST.split()
CDATELIST = config.CDATELIST.split()

VARLIST = config.VARLIST
VARLIST_OBS = config.VARLIST_OBS
VARLIST_OBS_FULLNAME = getattr(config, 'VARLIST_OBS_FULLNAME', VARLIST_OBS)
VARLIST_OBS_TYPE = config.VARLIST_OBS_TYPE

Nmonth = config.Nmonth
NENS = config.NENS
plot_monmean = config.plot_monmean.upper()
plot_diff = config.plot_diff.upper()

lats, late = config.lats, config.late
lons, lone = config.lons, config.lone

PRESLEV = getattr(config, 'PRESLEV', "NO")
LEVS = getattr(config, 'LEVS', None)

# ======================================================================
# 3. Helper Functions
# ======================================================================
def area_weighted_mean(data_array):
    """Calculates the area-weighted mean over latitude and longitude."""
    weights = np.cos(np.deg2rad(data_array.lat))
    weights.name = "weights"
    return data_array.weighted(weights).mean(dim=["lat", "lon"]).values

def standardize_coords(ds):
    """Renames latitude/longitude to lat/lon if they exist."""
    rename_dict = {}
    if 'latitude' in ds.dims or 'latitude' in ds.coords:
        rename_dict['latitude'] = 'lat'
    if 'longitude' in ds.dims or 'longitude' in ds.coords:
        rename_dict['longitude'] = 'lon'
    return ds.rename(rename_dict) if rename_dict else ds

def extract_var(ds, expected_var):
    """Finds the variable in the dataset even if the case doesn't match exactly."""
    if expected_var in ds.data_vars:
        return ds[expected_var]
    
    for v in ds.data_vars:
        if v.lower() == expected_var.lower():
            return ds[v]
            
    main_vars = [v for v in ds.data_vars if 'bnd' not in v.lower() and 'bounds' not in v.lower()]
    if len(main_vars) >= 1:
        fallback = main_vars[0]
        print(f"  -> Warning: '{expected_var}' not found. Using available variable '{fallback}' instead.")
        return ds[fallback]

    raise KeyError(f"Variable '{expected_var}' not found. Available: {list(ds.data_vars.keys())}")

# ======================================================================
# 4. Main Plotting Loop
# ======================================================================
for CDATE in CDATELIST:
    plot_casemean = "YES" if "climate" in CDATE.lower() else "NO"

    for i, VAR in enumerate(VARLIST):
        VARANA = VARLIST_OBS[i] if i < len(VARLIST_OBS) else 'none'
        VARANA_FULL = VARLIST_OBS_FULLNAME[i] if i < len(VARLIST_OBS_FULLNAME) else 'none'
        VARANA_TYPE = VARLIST_OBS_TYPE[i].upper() if i < len(VARLIST_OBS_TYPE) else 'NONE'

        if VARANA_TYPE == "OISST":
            anafile = f"{ANADATADIR}/{config.OISSTFILENAME}"
        elif VARANA_TYPE == "CERES_CLD":
            anafile = f"{ANADATADIR}/{config.CERESFILENAME_CLD}"
        elif VARANA_TYPE == "CERES":
            anafile = f"{ANADATADIR}/{config.CERESFILENAME}"
        elif VARANA_TYPE == "CERES_SFC":
            anafile = f"{ANADATADIR}/{config.CERESFILENAME_SFC}"
        elif VARANA_TYPE == "ERA5_3D":
            anafile = f"{ANADATADIR}/ERA5_3D/{VARANA_FULL}.1994-2024.mon.1p0.nc"
        elif VARANA_TYPE == "GHCN_CAMS":
            anafile = f"{ANADATADIR}/{config.GHCNCAMSFILENAME}"
        elif VARANA_TYPE == "CMAP":
            anafile = f"{ANADATADIR}/{config.CMAPFILENAME}"
        else:
            anafile = f"{ANADATADIR}/{config.ERAFILENAME}"

        # Initialize shared colorbar limits outside the leadmonth loop
        shared_mean_levels = None
        shared_diff_levels = None

        # Reversed loop: starts from t_idx=0 (which evaluates to max leadmonth, e.g., 11)
        for t_idx in range(Nmonth):
            leadmonth = Nmonth - t_idx - 1
            
            try:
                base_date = pd.to_datetime(CDATE[:8], format='%Y%m%d')
                target_date = base_date + pd.DateOffset(months=t_idx)
                time_str = f"{target_date.year}-{target_date.month:02d}"
            except Exception as e:
                print(f"Error parsing CDATE {CDATE}: {e}")
                continue
            
            # --- Load Forecast Data ---
            fcst_data = []
            for exp in EXPLIST:
                if NENS > 0:
                    fname = f"{DATAOUT}/{VAR}/{exp}.{CDATE}.{VAR}.ensmean0-{NENS}.1p0.monthly.nc"
                else:
                    fname = f"{DATAOUT}/{VAR}/{exp}.{CDATE}.{VAR}.mem0.1p0.monthly.nc"
                
                try:
                    ds = xr.open_dataset(fname, decode_times=False)
                    ds = standardize_coords(ds)
                    if PRESLEV == 'YES' and LEVS:
                        ds = ds.sel(level=float(LEVS), method="nearest")
                    
                    ds = ds.sel(lat=slice(lats, late), lon=slice(lons, lone))
                    da = extract_var(ds, VAR).isel(time=t_idx)
                    
                    fcst_data.append({'exp': exp, 'da': da})
                except FileNotFoundError:
                    continue

            if not fcst_data:
                continue

            # --- Load OBS Data ---
            ana_da = None
            if VARANA_FULL != 'none':
                if plot_casemean == 'YES':
                    afname = f"{DATAOUT}/{VAR}/ANA.{CDATE}.{VAR}.1p0.monthly.nc"
                else:
                    afname = anafile
                
                try:
                    ds_ana = xr.open_dataset(afname, decode_times=True)
                    ds_ana = standardize_coords(ds_ana)
                    if PRESLEV == 'YES' and LEVS:
                        ds_ana = ds_ana.sel(level=float(LEVS), method="nearest")
                    
                    ds_ana = ds_ana.sel(lat=slice(lats, late), lon=slice(lons, lone))
                    
                    # Direct extraction
                    ana_da_raw = extract_var(ds_ana, VARANA_FULL).sel(time=time_str).squeeze()
                    ana_da = ana_da_raw 
                except (FileNotFoundError, KeyError) as e:
                    print(f"ANA data issue for {time_str}: {e}")

            n_exps = len(fcst_data)
            
            # ==================================================================
            # PRE-CALCULATE BIASES/DIFFS
            # ==================================================================
            mean_arrays = []
            diff_arrays = []

            if plot_monmean == 'YES':
                for item in fcst_data:
                    mean_arrays.append(item['da'].values)
                if ana_da is not None:
                    mean_arrays.append(ana_da.values)

            if ana_da is not None:
                for item in fcst_data:
                    da_interp = item['da'].interp_like(ana_da)
                    bias_da = da_interp - ana_da.values 
                    item['bias_da'] = bias_da
                    diff_arrays.append(bias_da.values)

            if n_exps >= 2 and plot_diff == 'YES':
                da_exp1 = fcst_data[0]['da']
                for item in fcst_data[1:]:
                    diff_da = item['da'] - da_exp1.values
                    item['diff_da'] = diff_da
                    diff_arrays.append(diff_da.values)
            
            # ==================================================================
            # ESTABLISH SHARED COLORBAR LIMITS ONLY ON THE FIRST PASS
            # ==================================================================
            if shared_mean_levels is None:
                if mean_arrays:
                    vmin_mean = np.nanmin([np.nanmin(arr) for arr in mean_arrays])
                    vmax_mean = np.nanmax([np.nanmax(arr) for arr in mean_arrays])
                    shared_mean_levels = MaxNLocator(nbins=20, integer=True).tick_values(vmin_mean, vmax_mean)

            if shared_diff_levels is None:
                if diff_arrays:
                    if VAR.lower() == 'sst' or VARANA_TYPE == "OISST":
                        shared_diff_levels = np.linspace(-4, 4, 17)
                    else:
                        vmax_diff = int(np.ceil(np.nanmax([np.nanmax(np.abs(arr)) * 0.3 for arr in diff_arrays])))
                        shared_diff_levels = MaxNLocator(nbins=20, integer=False, symmetric=True).tick_values(-vmax_diff, vmax_diff)

            # Map the finalized levels to the plotting loop variables
            mean_levels = shared_mean_levels
            diff_levels = shared_diff_levels

            # --- Setup Figure Layout ---
            total_plots = 0
            if plot_monmean == 'YES': total_plots += n_exps
            if ana_da is not None:
                if plot_monmean == 'YES': total_plots += 1
                total_plots += n_exps
            if n_exps >= 2 and plot_diff == 'YES': 
                total_plots += (n_exps - 1)
            
            if total_plots == 0:
                continue

            cols = 3
            rows = int(np.ceil(total_plots / cols))
            
            fig, axes = plt.subplots(rows, cols, figsize=(15, 5 * rows), 
                                     subplot_kw={'projection': ccrs.PlateCarree(central_longitude=180)})
            axes = axes.flatten() if total_plots > 1 else [axes]
            
            plot_idx = 0

            # --- Plot 1: Monthly Means ---
            if plot_monmean == 'YES':
                for item in fcst_data:
                    ax = axes[plot_idx]
                    da = item['da']
                    mean_val = area_weighted_mean(da)
                    im = ax.contourf(da.lon, da.lat, da, levels=mean_levels, cmap='turbo', 
                                     extend='both', transform=ccrs.PlateCarree())
                    ax.coastlines()
                    # Replaced axhline with plot
                    ax.plot([0, 360], [0, 0], color='black', linestyle=':', linewidth=1.2, transform=ccrs.PlateCarree())
                    ax.set_title(f"{item['exp']} {VAR} | mean={mean_val:.2f}\nNENS={NENS}")
                    fig.colorbar(im, ax=ax, orientation='horizontal', pad=0.05)
                    plot_idx += 1

            # --- Plot 2: OBS Mean & Biases ---
            if ana_da is not None:
                if plot_monmean == 'YES':
                    ax = axes[plot_idx]
                    mean_val = area_weighted_mean(ana_da)
                    im = ax.contourf(ana_da.lon, ana_da.lat, ana_da, levels=mean_levels, cmap='turbo', 
                                     extend='both', transform=ccrs.PlateCarree())
                    ax.coastlines()
                    # Replaced axhline with plot
                    ax.plot([0, 360], [0, 0], color='black', linestyle=':', linewidth=1.2, transform=ccrs.PlateCarree())
                    ax.set_title(f"{VARANA_TYPE} {VARANA_FULL} | mean={mean_val:.2f}")
                    fig.colorbar(im, ax=ax, orientation='horizontal', pad=0.05)
                    plot_idx += 1

                for item in fcst_data:
                    ax = axes[plot_idx]
                    bias_da = item['bias_da']
                    mean_bias = area_weighted_mean(bias_da)
                    
                    im = ax.contourf(bias_da.lon, bias_da.lat, bias_da, levels=diff_levels, cmap='PuOr_r', 
                                     extend='both', transform=ccrs.PlateCarree())
                    ax.coastlines()
                    # Replaced axhline with plot
                    ax.plot([0, 360], [0, 0], color='black', linestyle=':', linewidth=1.2, transform=ccrs.PlateCarree())
                    ax.set_title(f"{item['exp']} {VAR} Bias vs {VARANA_TYPE}\nmean={mean_bias:.2f}")
                    fig.colorbar(im, ax=ax, orientation='horizontal', pad=0.05)
                    plot_idx += 1

            # --- Plot 3: Experiment Differences ---
            if n_exps >= 2 and plot_diff == 'YES':
                for item in fcst_data[1:]:
                    ax = axes[plot_idx]
                    diff_da = item['diff_da']
                    mean_diff = area_weighted_mean(diff_da)
                    
                    im = ax.contourf(diff_da.lon, diff_da.lat, diff_da, levels=diff_levels, cmap='PuOr_r', 
                                     extend='both', transform=ccrs.PlateCarree())
                    ax.coastlines()
                    # Replaced axhline with plot
                    ax.plot([0, 360], [0, 0], color='black', linestyle=':', linewidth=1.2, transform=ccrs.PlateCarree())
                    ax.set_title(f"{item['exp']} - {fcst_data[0]['exp']} {VAR} Diff\nmean={mean_diff:.2f}")
                    fig.colorbar(im, ax=ax, orientation='horizontal', pad=0.05)
                    plot_idx += 1

            for ax in axes[plot_idx:]:
                ax.axis('off')

            plt.tight_layout()
            if PRESLEV == 'YES':
                fout = f"{fcst_data[0]['exp']}.diff_{VAR}{LEVS}_{CDATE}_leadmonth{leadmonth}.png"
            else:
                fout = f"{fcst_data[0]['exp']}.diff_{VAR}_{CDATE}_leadmonth{leadmonth}.png"
            plt.savefig(fout, dpi=300, bbox_inches='tight')
            plt.close()
            print(f"Saved {fout}")
