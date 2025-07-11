#!/bin/bash

#-----------------------------------------------------------
# Invoke as: sbatch $script
# # #-----------------------------------------------------------
# #
#SBATCH --ntasks=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH -J anom
#SBATCH -o log.YYYYMMDDHH
#SBATCH -e log.YYYYMMDDHH
####################  
## re-org data based on fcst lead months and get climate and anomaly
####################

module load cdo
source config.diag
rm -rf $WORKDIR
VARLIST="${VARLIST[*]}"
mkdir -p $WORKDIR
set -x
run_mean_if_files_exist() {
    local files=("$@")
    local out_file="${files[-1]}"
    unset 'files[-1]'

    missing=false
    for f in "${files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "Missing file: $f"
            missing=true
        fi
    done

    if [ "$missing" = false ]; then
        cdo ensmean "${files[@]}" "$out_file"
    else
        echo "Skipping mean for output: $out_file"
    fi
} 

# Function: reset_to_month_start <input_file> <output_file>
reset_to_month_start() {
    local input_file="$1"
    local output_file="$2"

    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' not found."
        return 1
    fi

    echo "Original date/time in $input_file:"
    cdo showdate "$input_file"

    # Extract first date
    local first_date
    first_date=$(cdo -s showdate "$input_file" | awk '{print $1}' | head -n 1)

    # Extract year and month
    local year month
    year=$(echo "$first_date" | cut -c1-4)
    month=$(echo "$first_date" | cut -c6-7)

    # Compose new date for time axis: 1st of the month at 00Z
    local new_date="${year}-${month}-01,00:00:00"

    # Define time step (customize if needed)
    local time_step="1day"

    echo "Setting new time axis: $new_date with step $time_step"

    # Apply new time axis
    cdo settaxis,"$new_date","$time_step" "$input_file" "$output_file"

    echo "New date/time in $output_file:"
    cdo showdate "$output_file"
}

#CHECK if all IC DATEs are same in CDATELIST, if not, stopped
first_mmdd=""
for CDATE in "${CDATELIST[@]}"; do
    mmdd="${CDATE:4:4}"

    if [[ -z "$first_mmdd" ]]; then
        first_mmdd="$mmdd"
    elif [[ "$mmdd" != "$first_mmdd" ]]; then
        echo "Error: Different MMDD values detected ($first_mmdd vs $mmdd). Stopping."
        exit 1
    fi
done
echo "All CDATEs have the same MMDD: $first_mmdd"

for exp in $EXPLIST;do
	for var in $VARLIST;do
# May1st and Nov1st 
            cd $WORKDIR
	    tmpdir=tmp.$var.$exp
            rm -rf $tmpdir
            mkdir $tmpdir
            cd $tmpdir
# generate files with forecast lead month
           for istep in $(seq 1 $Nmonth);do
	        echo $istep
                for iyear in $CDATELIST;do
	            CDATE=${iyear}
		    icdate=${CDATE:4:4}
	            echo $CDATE
	            file=$DATAOUT/$var/$exp.$CDATE.${var}
                    cdo seltimestep,$istep $file.1p0.monthly.nc $exp.$CDATE.$var.$icdate.leadmon$istep.nc

                done
                reset_to_month_start $exp.$CDATE.$var.$icdate.leadmon$istep.nc $exp.$CDATE.$var.$icdate.leadmon$istep.nc.1
                cdo mergetime $exp.*.$var.$icdate.leadmon$istep.nc.1 $exp.$var.$icdate.leadmon$istep.nc.1
		cdo setreftime,1980-01-01,00:00 -settunits,years $exp.$var.$icdate.leadmon$istep.nc.1 $exp.$var.$icdate.leadmon$istep.nc
		cp -pr $exp.$var.$icdate.leadmon$istep.nc $DATAOUT/$var/.

          done
# seaonal mean forecast
            run_mean_if_files_exist \
                         "$exp.$var.$icdate.leadmon2.nc" \
                         "$exp.$var.$icdate.leadmon3.nc" \
                         "$exp.$var.$icdate.leadmon4.nc" \
                         "$DATAOUT/$var/$exp.$var.$icdate.leadmon2-4.nc"

             run_mean_if_files_exist \
                         "$exp.$var.$icdate.leadmon5.nc" \
                         "$exp.$var.$icdate.leadmon6.nc" \
                         "$exp.$var.$icdate.leadmon7.nc" \
                         "$DATAOUT/$var/$exp.$var.$icdate.leadmon5-7.nc"

            run_mean_if_files_exist \
                         "$exp.$var.$icdate.leadmon8.nc" \
                         "$exp.$var.$icdate.leadmon9.nc" \
                         "$exp.$var.$icdate.leadmon10.nc" \
                         "$DATAOUT/$var/$exp.$var.$icdate.leadmon8-10.nc"

            run_mean_if_files_exist \
                         "$exp.$var.$icdate.leadmon11.nc" \
                         "$exp.$var.$icdate.leadmon12.nc" \
                         "$DATAOUT/$var/$exp.$var.$icdate.leadmon11-12.nc"
#monthly climate and anomaly
          for istep in $(seq 1 $Nmonth);do

    	      cdo ymonmean $exp.$var.$icdate.leadmon$istep.nc $DATAOUT/$var/$exp.$var.$icdate.leadmon$istep.climate.nc
	      cdo ymonsub $exp.$var.$icdate.leadmon$istep.nc $DATAOUT/$var/$exp.$var.$icdate.leadmon$istep.climate.nc $DATAOUT/$var/$exp.$var.$icdate.leadmon$istep.anom.nc
          done
#seasonal climate and anomaly
          monlist="2-4 5-7 8-10 11-12"
	  for mon in $monlist;do
		  file=$DATAOUT/$var/$exp.$var.$icdate.leadmon$mon.nc
	     if [[ -f "$file" ]]; then
            	  cdo ymonmean $file $DATAOUT/$var/$exp.$var.$icdate.leadmon$mon.climate.nc
	          cdo ymonsub $file  $DATAOUT/$var/$exp.$var.$icdate.leadmon$mon.climate.nc $DATAOUT/$var/$exp.$var.$icdate.leadmon$mon.anom.nc
             else
	       echo "Missing $file"
	       exit 1
             fi
          done

      done
      done
