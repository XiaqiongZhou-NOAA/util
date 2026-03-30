#!/bin/bash
#-----------------------------------------------------------
# Invoke as: sbatch $script
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH -J fv3
#SBATCH -o ./getcfs.log.0501
#SBATCH -e ./getcfs.log.0501


# Extract SST, T2M, and APCP separately from CFS forecast files
set -x

outputdir=/scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/util/sfs_diag/data1
datadir=/scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/data/cfs/fcst/
exp=cfs

# Define your list of variables here
varlist="APCP T2M SST"

RANDOM_NUM=$(shuf -i 1-100 -n 1)
tmpdir=tmpdir$RANDOM_NUM

module load nco
module load cdo
module load wgrib2 

rm -rf $tmpdir
mkdir $tmpdir
cd $tmpdir

cat <<EOF > grid.txt
gridtype = lonlat
xsize    = 360
ysize    = 181
xfirst   = 0
xinc     = 1.
yfirst   = -90
yinc     = 1.0
xname    = longitude
yname    = latitude
EOF

MMDD=0301
mmddhhlist="022500 022506 022512 022518 022000 022006 022012 022018 021500 021506 021512"
MMDD=0501
mmddhhlist="050100 050106 050112 050118 042618 042612 042606 042600 042100 042106 042112"
NENS=$(echo $mmddhhlist | wc -w)
(( NENS=NENS-1 ))

for VAR in $varlist; do
    # Create variable-specific output directory if it doesn't exist
    mkdir -p $outputdir/$VAR
    
    for YYYY in {1991..2024..1}; do
        CDATE=${YYYY}${MMDD}00
        ICDATE=$(date -d "${CDATE:0:8}" +"%Y-%m-%d")
        
        member=0
        for mmddhh in $mmddhhlist; do 
            ICCDATE=${YYYY}${mmddhh}

            for LEAD in $(seq 0 8); do
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
                if [ ! -f "$datadir/$infile" ]; then
                    echo "Missing file: $datadir/$infile "
                    all_exist=false
                    stop
                else
                    wgrib2 $datadir/$infile -match "$match_str" -netcdf tmp_raw.$LEAD.nc
		    if [ $? -ne 0 ]; then
                            echo "wgrib2 failed for $infile"
                            stop
                    fi

		    cdo remapbil,grid.txt tmp_raw.$LEAD.nc tmp_raw.$LEAD.1.nc
                    cdo -chname,$rename_str tmp_raw.$LEAD.1.nc $VAR.$member.$LEAD.nc
                    rm tmp_raw.$LEAD.nc tmp_raw.$LEAD.1.nc
                fi
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

        # Remove old output if it exists
        ensmean_out="$outputdir/$VAR/$exp.$CDATE.$VAR.ensmean0-$NENS.1p0.monthly.nc"
        ensstd_out="$outputdir/$VAR/$exp.$CDATE.$VAR.ensstd0-$NENS.1p0.monthly.nc"
        [ -f "$ensmean_out" ] && rm -f "$ensmean_out"
        [ -f "$ensstd_out" ] && rm -f "$ensstd_out"

	 files=$(printf "$outputdir/$VAR/$exp.$CDATE.$VAR.mem%d.1p0.monthly.nc $seq 0 $NENS))
	 for f in $files; do
             if [ ! -f "$f" ]; then
                 echo "Missing file: $f"
                all_exist=false
                stop
             fi
        done

      if $all_exist; then


        # Run ensmean (safe since all files exist)
        cdo ensmean $files "$ensmean_out"
        cdo ensstd $files "$ensstd_out"
    else
        echo "Warning: Not all member files exist. Skipping ensmean."
    fi

    done
done
