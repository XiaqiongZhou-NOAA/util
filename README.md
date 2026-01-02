Required modules: WGRIB2, CDO and GrADS.   \
**1) atm_monmean_ens.sh**: calculate monthly mean based on the $VARLIST. It uses wgrib2 to exact variables from grib2 files  and interoplate to 1 degree resoluton then use cdo to calculate monthly mean. 
                
**2) ocn_monmean_ens.sh**: calculate monthly mean based on $VARLIST. It use CDO to select variables from netcdf files (can be atmos or ocean history), interpolate and get monthly mean. 
                
**3) plot.sh**: Use Grads to plot 2D maps to compare multiple experiments with  ERA5/CERES/OISST if avaible in $ERAFILENAME/CERESFILENAME/CERESFILENAME_CLD/OISSTFILENAME defined in $VARLIST_OBS and VARLIST_OBS_TYPE. "none" means obs or analysis are not available. 
         
**4) atm_plot_zonal_mean.sh**: to plot 3D variable zonal mean compared with ERA5 

**5) climate_leadmon_ens_obs.sh**: Re-org fcst and obs data based on ensemble forecast lead months and calcualte climate and anom 

(Figure examples: https://www.emc.ncep.noaa.gov/gc_wmb/xzhou//SFS/c192sfs_zm/)


