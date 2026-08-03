# Extract SST, T2M, and APCP separately from CFS forecast files
set -x

outputdir=/scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/util/sfs_diag/data/
datadir=/scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/data/cfs/fcst/
exp=cfs

# Define your list of variables here
varlist="SST T2M APCP"

RANDOM_NUM=$(shuf -i 1-100 -n 1)
tmpdir=tmpdir$RANDOM_NUM

module load nco
module load cdo
module load wgrib2 

rm -rf $tmpdir
mkdir $tmpdir
cd $tmpdir

MMDD=0501
mmddhhlist="050100 050106 050112 050118 042618 042612 042606 042600"
NENS=$(echo $mmddhhlist | wc -w)

for VAR in $varlist; do
    # Create variable-specific output directory if it doesn't exist
    mkdir -p $outputdir/$VAR
    
    for YYYY in {2013..2013..1}; do
        CDATE=${YYYY}${MMDD}00
        ICDATE=$(date -d "${CDATE:0:8}" +"%Y-%m-%d")
        
        member=0
        for mmddhh in $mmddhhlist; do 
            ICCDATE=${YYYY}${mmddhh}

            for LEAD in $(seq 0 9); do
                fcst_YYYYMM=$(date -u -d "${CDATE:0:8} +${LEAD} month" +"%Y%m")
                
                # Logic to select the correct file and GRIB search string based on VAR
                case $VAR in
                    SST)
                        infile="ocnf.01.${ICCDATE}.${fcst_YYYYMM}.avrg.grib.grb2"
                        match_str="TMP:surface"
			rename_str="TMP_surface,sst"
                        ;;
                    T2M)
                        infile="flxf.01.${ICCDATE}.${fcst_YYYYMM}.avrg.grib.grb2"
                        match_str="TMP:2 m above ground"
                        rename_str="TMP_2maboveground,t2m"
                        ;;
                    APCP)
                        infile="flxf.01.${ICCDATE}.${fcst_YYYYMM}.avrg.grib.grb2"
                        match_str="PRATE"
                        rename_str="PRATE_surface,apcp"
                        ;;
                    UGRD)
                      infile="pgbf.01.${ICCDATE}.${fcst_YYYYMM}.avrg.grib.grb2"
		      match_str="UGRD:.[0-9]+ mb"
                        rename_str="UGRD,UGRD"
                        ;;

                esac

                # Extract and Rename
                wgrib2 $datadir/$infile -match "$match_str" -netcdf tmp_raw.$LEAD.nc
                cdo -chname,$rename_str tmp_raw.$LEAD.nc $VAR.$member.$LEAD.nc
                rm tmp_raw.$LEAD.nc
            done

            # Merge time steps for this member/variable
            cdo mergetime $VAR.$member.*.nc $VAR.merged.$member.nc
            
            # Set time axis and move to final destination
            cdo settaxis,$ICDATE,00:00:00,1month $VAR.merged.$member.nc \
                $outputdir/$VAR/$exp.$CDATE.$VAR.mem$member.1p0.monthly.nc
            
            rm $VAR.$member.*.nc $VAR.merged.$member.nc
            (( member=member+1 ))
        done

        # Calculate Ensemble Mean for this specific variable
        cdo ensmean $outputdir/$VAR/$exp.$CDATE.$VAR.mem*.1p0.monthly.nc \
            $outputdir/$VAR/$exp.$CDATE.$VAR.ensmean0-$NENS.1p0.monthly.nc
    done
done
