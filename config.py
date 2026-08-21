import time

machine = "hercules"

# ATMO variables
VARLIST = [
    "ALBDO", "DSWRFSFC", "DLWRFSFC", "USWRFSFC", "ULWRFSFC", "USWRFTOA", 
    "ULWRFTOA", "DSWRFTOA", "APCP", "ACPCP", "NCPCP", "TCOLW", "TCOLI", 
    "TCOLC", "TCOLS", "LCDC", "MCDC", "HCDC", "TCDC", "T2M", "U10M", 
    "V10M", "PWAT", "CAPE", "CWAT", "TMAX2M", "WIND10M", "TMIN2M"
]

VARLIST_OBS = [
    "ini_albedo_mon*100", "adj_sw_dn_all_s", "adj_lw_dn_all_s", "adj_sw_up_all_s", 
    "adj_atmos_lw_up", "adj_sw_up_all_t", "adj_lw_up_all_t", "adj_sw_dw_all_t",
    "var228*1000/4", "none", "none", "tclw", "tciw", "none", "none",
    "cldarea_low_mon", "cldarea_mid_low", "cldarea_high_mo", "cldarea_total_m",
    "t2m", "u10", "v10", "none", "none", "none", "none", "si10", "none"
]

VARLIST_OBS_FULLNAME = [
    "ini_albedo_mon", "adj_sw_dn_all_s", "adj_lw_dn_all_s", "adj_sw_up_all_s", 
    "adj_atmos_lw_up", "adj_sw_up_all_t", "adj_lw_up_all_t", "adj_sw_dw_all_t",
    "var228", "none", "none", "tclw", "tciw", "none", "none",
    "cldarea_low_mon", "cldarea_mid_low", "cldarea_high_mo", "cldarea_total_m",
    "t2m", "u10", "v10", "none", "none", "none", "none", "si10", "none"
]

VARLIST_OBS_TYPE = [
    "ceres_cld", "ceres", "ceres", "ceres", "ceres", "ceres", "ceres", "ceres", 
    "era5", "era5", "era5", "era5", "era5", "era5", "era5", 
    "ceres_cld", "ceres_cld", "ceres_cld", "ceres_cld", 
    "era5", "era5", "era5", "era5", "era5", "era5", "era5", "era5", "era5"
]

INTERPFLAG_ATM = "YES"
INTERPFLAG_OCN = "YES"

# Ocean netcdf (Note: In your original script, this overrides the previous ATMO VARLISTs)
VARLIST = ["APCP", "T2M", "SST"]
VARLIST_OBS = ["apcp_surface", "t2m", "sst"]
VARLIST_OBS_FULLNAME = ["apcp", "t2m", "sst"]
VARLIST_OBS_TYPE = ["cmap", "ghcn_cams", "oisst"]

FHMAX = 8796
NENS = 10
GET_ENSSTAT = "YES"
INTV_OCN = 24
INTV_ATM = 6

# Note: Keeping only the final uncommented CDATELIST and EXPLIST from your script
CDATELIST = "2024030100 2024040100 2024060100 2024070100 20240110100"
EXPLIST = "sfsbeta1 SFS_C192mx025_GFSV17ICs"

# For plotting 
Nmonth = 12
GRADSDIR = "./grads-scripts"
LEADMON = "1 2 3 4 5 6 7 8 9 10 11 12 2-4"
cmap_field = "radar"
cmap_bias = "blue2red"
cmap_diff = "blue2red"
plot_monmean = "YES"
plot_diff = "YES"
plot_2dmaps = "NO"
plot_timeseries = "YES"

# z-y zonal mean plot
LEVS = 1000
LEVE = 50
LEVLISTS = "900 850 600"

# Define plotting domain
lats = -90
late = 90
lons = 0
lone = 360

# File name of obs and analysis
ERAFILENAME = "pressfc.mon.1991-2025.1p0.nc"
CERESFILENAME = "CERES_SYN1deg-Month_Terra-Aqua-MODIS_Ed4.1_Subset_200003-202407.nc"
CERESFILENAME_SFC = "CERES_EBAF_Ed4.2_Subset_200003-202407.nc"
CERESFILENAME_CLD = "CERES_SYN1deg-Month_Terra-Aqua-NOAA20_Ed4.2_Subset_200003-202505.nc"
OISSTFILENAME = "sst.1p0.monthly.1991_2025.nc"
CMAPFILENAME = "cmap.mon.mean.1991-2025.1p0.nc"
GHCNCAMSFILENAME = "ghcn_cams.mon.mean.1991-2025.1p0.nc"

# Directories (Keeping only the active Orion variables at the bottom of your script)
USER = "Xiaqiong.Zhou" # Replaced $USER with the specific username found in your ANADATADIR path
DATAIN_MON = f"/scratch4/BMC/gsienkf/Philip.Pegion/SFS/"
RANDOM_NUM = int(time.time()) % 100 + 1
WORKDIR = f"/scratch4/NCEPDEV/stmp/{USER}/sfs_diag{RANDOM_NUM}"
ANADATADIR = f"/scratch4/NCEPDEV/ensemble/{USER}/data/sfs_diag_ana"
DATAIN = f"/scratch3/NCEPDEV/global/Yangxing.Zheng/"
DATAOUT = f"/scratch4/NCEPDEV/ensemble/{USER}/util/sfs_diag/data1"
