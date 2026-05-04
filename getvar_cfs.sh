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
#set -x

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

NENS=10
MM=04
START_YEAR=1992
END_YEAR=2024
MMDD=${MM}01


declare -A mmdd_list=(
  ["01"]="0101 1227 1222"
  ["02"]="0131 0126 0121"
  ["03"]="0225 0220 0215"
  ["04"]="0401 0327 0322"
  ["05"]="0501 0426 0421"
  ["06"]="0531 0526 0521"
  ["07"]="0630 0625 0620"
  ["08"]="0730 0725 0720"
  ["09"]="0829 0824 0819"
  ["10"]="0928 0923 0918"
  ["11"]="1028 1023 1018"
  ["12"]="1127 1122 1117"
)

mmddlist="${mmdd_list[$MM]}"

# get list of start time as ensemble member:mmddhhlist
((nnn=$NENS+1))
mmddhhlist=()
for d in $mmddlist; do
  for h in 18 12 06 00; do
    mmddhhlist+=("${d}${h}")
    [[ ${#mmddhhlist[@]} -ge $nnn ]] && break 2
  done
done

echo  ${mmddhhlist[@]}

for VAR in $varlist; do
    # Create variable-specific output directory if it doesn't exist
    mkdir -p $outputdir/$VAR
    
    for ((YYYY=START_YEAR; YYYY<=END_YEAR; YYYY+=1)); do
	mkdir $YYYY
	cd $YYYY
        cp -pr ../grid.txt .
        CDATE=${YYYY}${MMDD}00
        ICDATE=$(date -d "${CDATE:0:8}" +"%Y-%m-%d")
        
        member=0
        for mmddhh in ${mmddhhlist[@]}; do 
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
            
            #rm $VAR.$member.*.nc $VAR.merged.$member.nc
            (( member=member+1 ))
        done  #member

        # Calculate Ensemble Mean for this specific variable

        # Remove old output if it exists
        ensmean_out="$outputdir/$VAR/$exp.$CDATE.$VAR.ensmean0-$NENS.1p0.monthly.nc"
        ensstd_out="$outputdir/$VAR/$exp.$CDATE.$VAR.ensstd0-$NENS.1p0.monthly.nc"
        [ -f "$ensmean_out" ] && rm -f "$ensmean_out"
        [ -f "$ensstd_out" ] && rm -f "$ensstd_out"

	 files=$(printf "$outputdir/$VAR/$exp.$CDATE.$VAR.mem%d.1p0.monthly.nc " $(seq 0 $NENS))
	 for f in $files; do
             if [ ! -f "$f" ]; then
                 echo "Missing file: $f"
                all_exist=false
                break
             fi
        done

      if $all_exist; then


        # Run ensmean (safe since all files exist)
        cdo ensmean $files "$ensmean_out"
        cdo ensstd $files "$ensstd_out"
       else
           echo "Warning: Not all member files exist. Skipping ensmean."
       fi
       cd ../
 done #year
done #var
