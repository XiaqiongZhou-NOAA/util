#!/bin/bash
#-----------------------------------------------------------
# Invoke as: sbatch $script
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH --partition=service
#SBATCH -J fv3_refcst.1102
#SBATCH -e ./log.1102
#SBATCH -o ./log.1102

module load hpss
module load cdo
cd /scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/data/cfs/fcst/
BASE_URL="https://www.ncei.noaa.gov/thredds/fileServer/model-cfs-allfile-reforecast/high-priority-subset/monthly-means-9-month"
BASE_URL="https://www.ncei.noaa.gov/thredds/fileServer/model-cfs-allfile-operational-forecast/monthly-means"
BASE_URL="https://www.ncei.noaa.gov/data/climate-forecast-system/access/operational-9-month-forecast/monthly-means/"


MM=04

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

for mmdd in  $mmddlist ;do
#for mmdd in  0302 0225 0220 0215;do

for BASE_YEAR in $(seq 2012 2024); do
            # Default year
    YEAR=$BASE_YEAR

    # Adjust year for January + December dates
    if [[ "$MM" == "01" && "${mmdd:0:2}" == "12" ]]; then
      YEAR=$((BASE_YEAR - 1))
    fi


  # Fixed cycle: YEAR110100
  for cyc in 00 06 12 18;do
  CYCLE="${YEAR}$mmdd${cyc}"
  YYYYMM="${CYCLE:0:6}"
  YYYYMMDD="${CYCLE:0:8}"
  YEAR="${CYCLE:0:4}"
  URL="${BASE_URL}/${YEAR}/${YYYYMM}/${YYYYMMDD}/${CYCLE}"


  for LEAD in $(seq 0 8); do
    # Compute forecast valid month (YYYYMM)
    TARGET_YYYYMM=$(date -u -d "${YEAR}-${MM}-01 +${LEAD} month" +"%Y%m")


    #fcst
     FILE_FCST="01.${CYCLE}.${TARGET_YYYYMM}.avrg.grib"
    #refcst
    FILE_RFCST="${CYCLE}.01.${TARGET_YYYYMM}.avrg"
       for prefx in ocnf flxf;do
                  FILE=$prefx.${FILE_FCST}

            if [ ! -f "$FILE.grb2" ]; then
                  echo "ERROR: File not found: $FILE.grb2" 
		  wget $URL/$FILE.grb2
                  if [ ! -f "$FILE.grb2" ]; then
			 file=
	                 wget $URL/$FILE.00Z.grb2
                         wget $URL/$FILE.06Z.grb2
                         wget $URL/$FILE.12Z.grb2
                         wget $URL/$FILE.18Z.grb2
                         cdo ensmean $FILE.00Z.grb2 $FILE.06Z.grb2 $FILE.12Z.grb2 $FILE.18Z.grb2 $FILE.grb2
                  fi

            else
            echo "FIND $FILE.grib2"

        fi


 
       done
    done
    done
done
done
