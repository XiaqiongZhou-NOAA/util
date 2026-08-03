#!/bin/bash
#-----------------------------------------------------------
# Invoke as: sbatch $script
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH --partition=service
#SBATCH -J cfs_fcst_data
#SBATCH -e ./log.fcst
#SBATCH -o ./log.fcst

##set -x
module load hpss
cd /scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/data/cfs/fcst/

REFCST_URL="https://www.ncei.noaa.gov/data/climate-forecast-system/access/reforecast/high-priority-subset/monthly-means-9-month"


BASE_URL="https://www.ncei.noaa.gov/thredds/fileServer/model-cfs-allfile-operational-forecast/monthly-means"
BASE_URL="https://www.ncei.noaa.gov/data/climate-forecast-system/access/operational-9-month-forecast/monthly-means/"


MM=04
START_YEAR=2012
END_YEAR=2024

#Check refcst  date with availabe data

START_DATE="1990-${MM}-01"
mmddlist=""

for DAY_OFFSET in $(seq 0 14); do

    CHECK_DATE=$(date -u -d "${START_DATE} -${DAY_OFFSET} day" +"%Y%m%d")
    echo $CHECK_DATE  $DAY_OFFSET
    YYYYMM="${CHECK_DATE:0:6}"
    YYYY="${CHECK_DATE:0:4}"
    YYYYMMDD="${CHECK_DATE}"
    DIR_URL="${REFCST_URL}/${YYYY}/${YYYYMM}/${YYYYMMDD}"
    HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" "$DIR_URL/")

    if [ "$HTTP_CODE" == "200" ]; then
        MMDD="${CHECK_DATE:4:4}"
        echo "FOUND directory: $DIR_URL"
	mmddlist="$mmddlist $MMDD"
    fi

done   
echo $mmddlist
for mmdd in $mmddlist ;do
for YEAR in $(seq $START_YEAR $END_YEAR); do

  # Fixed cycle: YEAR110100
  for cyc in 00 06 12 18;do
  CYCLE="${YEAR}${mmdd}$cyc"
  YYYYMM="${CYCLE:0:6}"
  YYYYMMDD="${CYCLE:0:8}"
  echo CYCLE=$CYCLE
  echo YYYYMM=$YYYYMM

  for LEAD in $(seq 0 10); do
    # Compute forecast valid month (YYYYMM)
    TARGET_YYYYMM=$(date -u -d "${YEAR}-${MM}-01 +${LEAD} month" +"%Y%m")

    FILE_PGB="pgbf.01.${CYCLE}.${TARGET_YYYYMM}.avrg.grib.grb2"
    FILE_FLX="flxf.01.${CYCLE}.${TARGET_YYYYMM}.avrg.grib.grb2"
    FILE_OCN="ocnf.01.${CYCLE}.${TARGET_YYYYMM}.avrg.grib.grb2"
    for FILE in $FILE_PGB $FILE_FLX $FILE_OCN;do
       URL="${BASE_URL}/${YEAR}/${YYYYMM}/${YYYYMMDD}/${CYCLE}/${FILE}"

       echo "Downloading ${URL}"
       wget -c "$URL"
    done
  done
  done
done
done

