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

current_dir=$PWD
cd $current_dir
module load cdo
source config.diag

rm -rf $WORKDIR
#VARLIST="${VARLIST[*]}"
mkdir -p $WORKDIR
echo WORKDIR=$WORKDIR
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
    local time_step="1year"

    echo "Setting new time axis: $new_date with step $time_step"

    # Apply new time axis
    cdo settaxis,"$new_date","$time_step" "$input_file" "$output_file"

    echo "New date/time in $output_file:"
    cdo showdate "$output_file"
}

#CHECK if all IC DATEs are same in CDATELIST, if not, stopped
first_mmdd=""
for CDATE in $CDATELIST; do
    mmdd="${CDATE:4:4}"

    if [[ -z "$first_mmdd" ]]; then
        first_mmdd="$mmdd"
    elif [[ "$mmdd" != "$first_mmdd" ]]; then
        echo "Error: Different MMDD values detected ($first_mmdd vs $mmdd). Stopping."
        exit 1
    fi
done
echo "All CDATEs have the same MMDD: $first_mmdd"
CDATEARRAY=($CDATELIST)
CASE_NUM=${#CDATEARRAY[@]}
iexp=0
for exp in $EXPLIST;do
  ((iexp++))
  for i in "${!VARLIST[@]}"; do
    var=${VARLIST[$i]}
    echo i=$i var=$var
    echo VARLIST=$VARLIST
#    VAR=$(echo "$VAR" | tr  '[:lower:]' '[:upper:]')
    VARANA=${VARLIST_OBS_FULLNAME[$i]}
    VARANA_TYPE=${VARLIST_OBS_TYPE[$i]}
    VARANA_TYPE=$(echo "$VARANA_TYPE" | tr  '[:lower:]' '[:upper:]')
    if [ "$VARANA_TYPE" = "OISST" ]; then
           anafile=$ANADATADIR/$OISSTFILENAME
    elif [ "$VARANA_TYPE" = "CERES_CLD" ]; then
            anafile=$ANADATADIR/$CERESFILENAME_CLD
    elif [ "$VARANA_TYPE" = "CERES" ]; then
            anafile=$ANADATADIR/$CERESFILENAME
    elif [ "$VARANA_TYPE" = "CERES_SFC" ]; then
            anafile=$ANADATADIR/$CERESFILENAME_SFC
    elif [ "$VARANA_TYPE" = "ERA5_3D" ]; then
           anafile=$ANADATADIR/ERA5_3D/$VARANA.1994-2024.mon.1p0.nc
    else
           anafile=$ANADATADIR/$ERAFILENAME
    fi
    echo "Model variable: $VAR"
    echo "OBS variable:   $VARANA"
    echo "Reference file: $anafile"

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
		    if [ $NENS -gt 0 ]; then
	               filein=$exp.$CDATE.${var}.mem0-$NENS.1p0.monthly
	            else
	               filein=$exp.$CDATE.${var}.mem0.1p0.monthly
		    fi
		    #fcst
		    fileout=$exp.$CDATE.$var.${icdate}.leadmon$istep
                    cdo seltimestep,$istep $DATAOUT/$var/$filein.nc $fileout.nc
                    reset_to_month_start $fileout.nc $fileout.nc.1
	 	    year=${CDATE:0:4}
                    month=${CDATE:4:2}
                    day=${CDATE:6:2}
                    hour=${CDATE:8:2}
		    (( istep1 = istep-1 ))
		    newdate=$(date -d "$(date -d "${year}-${month}-${day} ${hour}:00" +%Y-%m-01) +${istep1} month" +%Y%m%d%H)
		    newyear=${newdate:0:4}
                    newmonth=${newdate:4:2}
		    echo newdate=$newdate

		    # corresponding ANA/OBS
                    if [[ "${VARANA}" != "none" && ${iexp} -eq 1 ]]; then
		      cdo -L selmon,$newmonth -selyear,$newyear -selvar,$VARANA $anafile ANA.$CDATE.$var.$icdate.leadmon$istep.nc
		    fi

                done
		#merge based on leadmonth 
		fileout=$exp.$var.${icdate}.leadmon$istep
                cdo mergetime $exp.*.$var.$icdate.leadmon$istep.nc.1 $fileout.nc.1
		cdo setreftime,1980-01-01,00:00 -settunits,years $fileout.nc.1 $fileout.nc
#		cp -pr $exp.$var.$icdate.leadmon$istep.nc $DATAOUT/$var/.
                if [[ "${VARANA}" != "none"  && ${iexp} -eq 1 ]]; then

                   cdo mergetime  ANA.*.$var.$icdate.leadmon$istep.nc ANA.$var.$icdate.leadmon$istep.nc.1
		   cdo setreftime,1980-01-01,00:00 -settunits,years ANA.$var.$icdate.leadmon$istep.nc.1 ANA.$var.$icdate.leadmon$istep.nc
		fi
#		cp -pr ANA.$var.$icdate.leadmon$istep.nc $DATAOUT/$var/.
          done

#monthly climate and anomaly
          rm -rf $DATAOUT/$var/$exp.$var.$icdate.climate.${CASE_NUM}yr.leadmon*.nc
          if [[ "${VARANA}" != "none"  && ${iexp} -eq 1 ]]; then
             rm -rf $DATAOUT/$var/ANA.$var.$icdate.climate.${CASE_NUM}yr.leadmon*.nc
	  fi
          for istep in $(seq 1 $Nmonth);do

              filein=$exp.$var.${icdate}.leadmon$istep
              fileout_climate=$exp.$var.${icdate}.climate.${CASE_NUM}yr.leadmon$istep
              fileout_anom=$exp.$var.${icdate}.anom.${CASE_NUM}yr.leadmon$istep
	      rm -rf  $DATAOUT/$var/${fileout_climate}.nc
	      rm -rf $DATAOUT/$var/${fileout_anom}.nc
    	      cdo ymonmean ${filein}.nc $DATAOUT/$var/${fileout_climate}.nc
	      cdo ymonsub $filein.nc $DATAOUT/$var/${fileout_climate}.nc $DATAOUT/$var/${fileout_anom}.nc
              if [[ "${VARANA}" != "none"  && ${iexp} -eq 1 ]]; then
    	          cdo ymonmean ANA.$var.$icdate.leadmon$istep.nc $DATAOUT/$var/ANA.$var.$icdate.climate.${CASE_NUM}yr.leadmon$istep.nc
	          cdo ymonsub ANA.$var.$icdate.leadmon$istep.nc $DATAOUT/$var/ANA.$var.$icdate.climate.${CASE_NUM}yr.leadmon$istep.nc $DATAOUT/$var/ANA.$var.$icdate.anom.${CASE_NUM}yr.leadmon$istep.nc
	      fi
          done
# merge leadmean  in one file
         rm -rf $DATAOUT/$var/$exp.$var.$icdate.climate.${CASE_NUM}yr.1p0.monthly.nc
         cdo mergetime  $(seq -f "$DATAOUT/$var/$exp.$var.$icdate.climate.${CASE_NUM}yr.leadmon%g.nc" 1 $Nmonth)  $exp.$var.$icdate.climate.${CASE_NUM}yr.1p0.monthly.nc
	 cdo setreftime,1980-01-01,00:00 -settunits,months $exp.$var.$icdate.climate.${CASE_NUM}yr.1p0.monthly.nc $DATAOUT/$var/$exp.$var.$icdate.climate.${CASE_NUM}yr.1p0.monthly.nc
         if [[ "${VARANA}" != "none"  && ${iexp} -eq 1 ]]; then
            rm -f $DATAOUT/$var/ANA.$var.$icdate.climate.${CASE_NUM}yr.1p0.monthly.nc
            cdo mergetime  $(seq -f "$DATAOUT/$var/ANA.$var.$icdate.climate.${CASE_NUM}yr.leadmon%g.nc" 1 $Nmonth) ANA.$var.$icdate.climate.${CASE_NUM}yr.1p0.monthly.nc
	    cdo setreftime,1980-01-01,00:00 -settunits,months ANA.$var.$icdate.climate.${CASE_NUM}yr.1p0.monthly.nc $DATAOUT/$var/ANA.$var.$icdate.climate.${CASE_NUM}yr.1p0.monthly.nc
	 fi

# seaonal mean forecast
            run_mean_if_files_exist \
                         "$exp.$var.$icdate.leadmon2.nc" \
                         "$exp.$var.$icdate.leadmon3.nc" \
                         "$exp.$var.$icdate.leadmon4.nc" \
                         "$exp.$var.$icdate.leadmon2-4.nc"
	    reset_to_month_start $exp.$var.$icdate.leadmon2-4.nc $DATAOUT/$var/$exp.$var.$icdate.leadmon2-4.nc

             run_mean_if_files_exist \
                         "$exp.$var.$icdate.leadmon5.nc" \
                         "$exp.$var.$icdate.leadmon6.nc" \
                         "$exp.$var.$icdate.leadmon7.nc" \
                         "$exp.$var.$icdate.leadmon5-7.nc"
	    reset_to_month_start $exp.$var.$icdate.leadmon5-7.nc $DATAOUT/$var/$exp.$var.$icdate.leadmon5-7.nc

            run_mean_if_files_exist \
                         "$exp.$var.$icdate.leadmon8.nc" \
                         "$exp.$var.$icdate.leadmon9.nc" \
                         "$exp.$var.$icdate.leadmon10.nc" \
                         "$exp.$var.$icdate.leadmon8-10.nc"
	    reset_to_month_start $exp.$var.$icdate.leadmon8-10.nc $DATAOUT/$var/$exp.$var.$icdate.leadmon8-10.nc

            run_mean_if_files_exist \
                         "$exp.$var.$icdate.leadmon11.nc" \
                         "$exp.$var.$icdate.leadmon12.nc" \
                         "$exp.$var.$icdate.leadmon11-12.nc"
	    reset_to_month_start $exp.$var.$icdate.leadmon11-12.nc $DATAOUT/$var/$exp.$var.$icdate.leadmon11-12.nc
# seaonal mean ANA
            if [[ "${VARANA}" != "none"  && ${iexp} -eq 1 ]]; then
                run_mean_if_files_exist \
                         "ANA.$var.$icdate.leadmon2.nc" \
                         "ANA.$var.$icdate.leadmon3.nc" \
                         "ANA.$var.$icdate.leadmon4.nc" \
                         "ANA.$var.$icdate.leadmon2-4.nc"
	        reset_to_month_start ANA.$var.$icdate.leadmon2-4.nc $DATAOUT/$var/ANA.$var.$icdate.leadmon2-4.nc

                run_mean_if_files_exist \
                         "ANA.$var.$icdate.leadmon5.nc" \
                         "ANA.$var.$icdate.leadmon6.nc" \
                         "ANA.$var.$icdate.leadmon7.nc" \
                         "ANA.$var.$icdate.leadmon5-7.nc"
	        reset_to_month_start ANA.$var.$icdate.leadmon5-7.nc $DATAOUT/$var/ANA.$var.$icdate.leadmon5-7.nc

                run_mean_if_files_exist \
                         "ANA.$var.$icdate.leadmon8.nc" \
                         "ANA.$var.$icdate.leadmon9.nc" \
                         "ANA.$var.$icdate.leadmon10.nc" \
                         "ANA.$var.$icdate.leadmon8-10.nc"
	       reset_to_month_start ANA.$var.$icdate.leadmon8-10.nc $DATAOUT/$var/ANA.$var.$icdate.leadmon8-10.nc

               run_mean_if_files_exist \
                         "ANA.$var.$icdate.leadmon11.nc" \
                         "ANA.$var.$icdate.leadmon12.nc" \
                         "ANA.$var.$icdate.leadmon11-12.nc"
	       reset_to_month_start ANA.$var.$icdate.leadmon11-12.nc $DATAOUT/$var/ANA.$var.$icdate.leadmon11-12.nc
	    fi

#seasonal climate and anomaly
          monlist="2-4 5-7 8-10 11-12"
	  for mon in $monlist;do
          #FCST
		  file=$DATAOUT/$var/$exp.$var.$icdate.leadmon$mon.nc
	     if [[ -f "$file" ]]; then
            	  cdo ymonmean $file $DATAOUT/$var/$exp.$var.$icdate.climate.${CASE_NUM}yr.leadmon$mon.nc
	          cdo ymonsub $file  $DATAOUT/$var/$exp.$var.$icdate.climate.${CASE_NUM}yr.leadmon$mon.nc $DATAOUT/$var/$exp.$var.$icdate.anom.${CASE_NUM}yr.leadmon$mon.nc
             else
	       echo "Missing $file"
	       exit 1
             fi
             if [[ "${VARANA}" != "none"  && ${iexp} -eq 1 ]]; then
	  #ANA
		  file=$DATAOUT/$var/ANA.$var.$icdate.leadmon$mon.nc
	        if [[ -f "$file" ]]; then
            	    cdo ymonmean $file $DATAOUT/$var/ANA.$var.$icdate.climate.${CASE_NUM}yr.leadmon$mon.nc
	            cdo ymonsub $file  $DATAOUT/$var/ANA.$var.$icdate.climate.${CASE_NUM}yr.leadmon$mon.nc $DATAOUT/$var/ANA.$var.$icdate.anom.${CASE_NUM}yr.leadmon$mon.nc
                else
	            echo "Missing $file"
	            exit 1
               fi
	     fi
          done

      done
      done
