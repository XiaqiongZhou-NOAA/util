#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH -J anome
#SBATCH -o log6
#SBATCH -e log6

# ==========================================================
# Climate Lead-Month Processing Script
# - Reorganize forecast by lead month
# - Extract corresponding ANA/OBS
# - Compute climatology and anomaly
# - Compute seasonal means
# ==========================================================

set -x
module load cdo
var=SST
CASE_NUM=34
icdate=1101
NENS=10
Nmonth=12
DATAOUT=/scratch4/NCEPDEV/ensemble/Xiaqiong.Zhou/util/sfs_diag/data1
EXPLIST="cfs C192mx025_sfs_reforecast_Nov01"

RANDOM_NUM=$(shuf -i 1-100 -n 1)
tmpdir=tmpdir$RANDOM_NUM


WORKDIR=$tmpdir
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd $WORKDIR

# ==========================================================
# Utility Functions
# ==========================================================


iexp=0
for exp in $EXPLIST; do
((iexp++))


for istep in $(seq 1 $Nmonth); do



    input1="$DATAOUT/$var/$exp.$icdate.${CASE_NUM}yr.$var.nmem$NENS.leadmon${istep}.nc"
    input2="$DATAOUT/$var/ANA.$icdate.${CASE_NUM}yr.$var.nmem$NENS.leadmon${istep}.nc"
    output="$exp.corr.$icdate.${CASE_NUM}yr.$var.nmem$NENS.leadmon${istep}.nino34.nc"
    cdo -L fldmean -sellonlatbox,190,240,-5,5 $input1 $exp.$istep.nc
    cdo -L fldmean -sellonlatbox,190,240,-5,5 $input2 ana.$istep.nc
    cdo -O -timcor $exp.$istep.nc ana.$istep.nc $output


done
    output="$exp.corr.$icdate.${CASE_NUM}yr.$var.nmem$NENS.nino34.nc"
   cdo mergetime $exp.corr.$icdate.${CASE_NUM}yr.$var.nmem$NENS.leadmon*.nino34.nc $output
   cdo -O -L setreftime,1980-01-01,00:00 -settunits,months $output $output.1
   cdo -settunits,days $output.1 $DATAOUT/$var/corr/$output

done

echo "Processing complete."
