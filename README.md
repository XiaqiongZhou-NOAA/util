Required modules: WGRIB2, CDO and GrADS; tested on WCOSS2 and HERA.

atm_monmean.sh: calculate monthly mean based on the $VARLIST. It uses wgrib2 to exact variables from grib2 files and interoplate to 1 degree resoluton then use cdo to 
                calculate monthly mean.
                
atm_plot.sh: Use Grads to plot 2D maps. Only two experiments can be compared. It also plot ERA5 analysis if data is avaible in $ERAFILENAME with varible name defined in $VARLIST_ERA and "none" means not available.

atm_plot_bias.sh: As atm_plot.sh except plot bias against ERA5 analysis when analysis is available.

ocn_monmean.sh: calculate monthly mean based on $VARLIST_OCN. It use CDO to select variables from netcdf files, interpolate and get monthly mean.

ocn_plot.sh:USe Grads to plot 2D maps. SW and LW are compared with CERES and SST is compared with OISST.


