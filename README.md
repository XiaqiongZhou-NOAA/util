Required modules: WGRIB2, CDO and GrADS; tested on WCOSS2 and HERA.

atm_monmean.sh: calculate monthly mean based on the $VARLIST. It uses wgrib2 to exact variables from grib2 files and interoplate to 1 degree resoluton then use cdo to 
                calculate monthly mean.
ocn_monmean.sh: calculate monthly mean based on $VARLIST_OCN. It use CDO to select variables from netcdf files, interpolate and get monthly mean.
                
plot.sh: Use Grads to plot 2D maps to compare multiple experiments with  ERA5/CERES/OISST if avaible in $ERAFILENAME/CERESFILENAME/CERESFILENAME_CLD/OISSTFILENAME defined in $VARLIST_OBS and VARLIST_OBS_TYPE. "none" means not available.
atm_plot_zonal_mean.sh: to plot 3D variable zonal mean compared with ERA5
climate_leadmon: Re-org fcst data based on forecast lead months and calcualte climate and anom
(Figure examples: https://www.emc.ncep.noaa.gov/gc_wmb/xzhou//SFS/c192sfs_zm/)


