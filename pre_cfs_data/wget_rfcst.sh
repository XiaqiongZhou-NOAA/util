#!/bin/bash
#-----------------------------------------------------------
# Invoke as: sbatch $script
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH --partition=service
#SBATCH -J cfs_refcst_data
#SBATCH -e ./log.refcst
#SBATCH -o ./log.refcst

#set -x
module load hpss
cd /scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/data/cfs/refcst/



BASE_URL="https://www.ncei.noaa.gov/thredds/fileServer/model-cfs-allfile-operational-forecast/monthly-means"
BASE_URL="https://www.ncei.noaa.gov/thredds/fileServer/model-cfs-allfile-reforecast/high-priority-subset/monthly-means-9-month"
BASE_URL="https://www.ncei.noaa.gov/thredds/fileServer/model-cfs-allfile-reforecast/high-priority-subset/monthly-means-9-month"
BASE_URL="https://www.ncei.noaa.gov/data/climate-forecast-system/access/reforecast/high-priority-subset/monthly-means-9-month"

MM=04
START_YEAR=1991
END_YEAR=1991

for YEAR in $(seq $START_YEAR $END_YEAR); do

	  # Start from first day of target month
  START_DATE="${YEAR}-${MM}-01"

  # Go back 30 days (covers previous month overlap)
  for DAY_OFFSET in $(seq 0 14); do

    CHECK_DATE=$(date -u -d "${START_DATE} -${DAY_OFFSET} day" +"%Y%m%d")
    echo $CHECK_DATE  $DAY_OFFSET
    YYYYMM="${CHECK_DATE:0:6}"
    YYYYMMDD="${CHECK_DATE}"
    DIR_URL="${BASE_URL}/${YEAR}/${YYYYMM}/${YYYYMMDD}"
    HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" "$DIR_URL/")

    if [ "$HTTP_CODE" == "200" ]; then
        echo "FOUND directory: $DIR_URL"

  # Fixed cycle: YEAR110100
       for cyc in 00 06 12 18  ;do
         CYCLE="${YYYYMMDD}${cyc}"
         YYYYMM="${CYCLE:0:6}"
         YYYYMMDD="${CYCLE:0:8}"

          for LEAD in $(seq 0 9); do
    # Compute forecast valid month (YYYYMM)
            TARGET_YYYYMM=$(date -u -d "${YEAR}-${MM}-01 +${LEAD} month" +"%Y%m")


            FILE_PGB="pgbf${CYCLE}.01.${TARGET_YYYYMM}.avrg.grb2"
            FILE_FLX="flxf${CYCLE}.01.${TARGET_YYYYMM}.avrg.grb2"
            FILE_OCN="ocnf${CYCLE}.01.${TARGET_YYYYMM}.avrg.grb2"
	    for  FILE in $FILE_PGB $FILE_FLX $FILE_OCN;do
                 URL="${BASE_URL}/${YEAR}/${YYYYMM}/${YYYYMMDD}/${FILE}"
                 HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" "$URL")

                 if [ "$HTTP_CODE" == "200" ]; then
                     echo "FOUND: $URL"
                     wget -c "$URL"
                 else
                     echo "MISS : $URL"
                 fi

                echo "Downloading ${URL}"
                wget -c "$URL"
           done
        done
      done
   fi 
done
done
