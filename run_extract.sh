#!/bin/bash

DATAIN=/scratch3/NCEPDEV/global/Yangxing.Zheng/
exp=C192mx025_sfs_reforecast_March01

DATAOUT=/scratch4/NCEPDEV/ensemble/$USER/util/sfs_diag/data1

DATAIN=$DATAIN/$exp



NENS=10

# list of dates
CDATES=`seq 1991 2024 | sed 's/$/110100/g'  `
echo $CDATES
for CDATE in ${CDATES}; do
    echo "Submitting job for $CDATE"

    sbatch -J "atm_$CDATE" \
       -A fv3-cpu \
       -q batch \
       -n 1 -N 1 \
       -t 06:30:00 \
       -o atm_${CDATE}.out \
       -e atm_${CDATE}.out \
        --export=ALL,CDATE=$CDATE,exp=$exp,NENS=$NENS,DATAOUT=$DATAOUT,DATAIN=$DATAIN extract_atm_prod.sh

    sbatch -J "ocn_$CDATE" \
       -A fv3-cpu \
       -q batch \
       -n 1 -N 1 \
       -t 06:30:00 \
       -o ocn_${CDATE}.out \
       -e ocn_${CDATE}.out \
        --export=ALL,CDATE=$CDATE,exp=$exp,NENS=$NENS,DATAOUT=$DATAOUT,DATAIN=$DATAIN extract_ocn_prod.sh
done
