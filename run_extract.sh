#!/bin/bash

DATAIN=/scratch3/NCEPDEV/global/Yangxing.Zheng/
exp=C192mx025_sfs_reforecast_March01

DATAOUT=/scratch4/NCEPDEV/ensemble/$USER/util/sfs_diag/data1

DATAIN=$DATAIN/$exp



NENS=10

# list of dates
CDATES=(1991030100 1992030100 1993030100 1994030100 1995030100 1996030100 1997030100 1998030100 1999030100 2000030100 2001030100 2002030100 2003030100 2004030100 2005030100 2006030100 2007030100 2008030100 2009030100 2010030100 2011030100 2012030100 2013030100 2014030100 2015030100 2016030100 2017030100 2018030100 2019030100 2020030100 2021030100 2022030100 2023030100 2024030100
)

for CDATE in "${CDATES[@]}"; do
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
