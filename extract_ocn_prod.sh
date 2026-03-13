#!/bin/bash
#-----------------------------------------------------------
# Invoke as: sbatch $script
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH -J fv3
#SBATCH -o ./log.ocn
#SBATCH -e ./log.ocn


set -x

module load cdo
module load wgrib2

#######################################
# configuration
#######################################

DATAIN=/scratch3/NCEPDEV/global/Yangxing.Zheng/
exp=SFS_NRT_C192mx025_20260301
DATAIN=/scratch4/NCEPDEV/stmp/Neil.Barton/RUNS/COMROOT/
exp=SFSBETA1.1_GFSv17ICs

DATAIN=$DATAIN/$exp
DATAOUT=/scratch4/NCEPDEV/ensemble/$USER/util/sfs_diag/data

GET_ENSSTAT=YES
NENS=30
CDATE=2026030100

pdy=${CDATE:0:8}
VARLIST="SSH SST speed MLD_003 MLD_0125 SSU SSV,ePBL latent sensible SW LW taux tauy temp so uo vo"

#######################################
# variable groups
#######################################



#######################################
# main variable loop
#######################################

for VAR in $VARLIST; do

mkdir -p $DATAOUT/$VAR

#######################################
# ensemble loop
#######################################

for m in $(seq 0 $((NENS))); do

member=$(printf "%03d" $m)

tmpdir=./tmpdir.ocn.$CDATE.$exp/$VAR.$member
mkdir -p $tmpdir

#######################################
# month loop
#######################################

for mon in $(seq 0 11); do

validyyyy=$(date -d "$pdy +$mon month" +%Y)
validmm=$(date -d "$pdy +$mon month" +%m)

file=$DATAIN/sfs.$pdy/00/mem${member}/products/ocean/netcdf/1p00/sfs.ocean.t$CDATE.1p00.monthly_avg.${validyyyy}-$validmm.nc

[[ -f $file ]] || continue


echo "find and reading $file ($VAR)"


cdo select,name=$VAR $file $tmpdir/${VAR}.${validyyyy}${validmm}.nc

done

#######################################
# output file
#######################################

outfile=$DATAOUT/$VAR/$exp.$CDATE.${VAR}.mem${m}.1p0.monthly.nc

#######################################
# daily → monthly mean
#######################################

rm -f $outfile
cdo mergetime $tmpdir/${VAR}.*.nc $outfile


echo "saved $outfile"

#rm -rf $tmpdir

done

#######################################
# ensemble statistics
#######################################

if [[ "$GET_ENSSTAT" == "YES" ]]; then

rm -rf $DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensmean0-${NENS}.1p0.monthly.nc
rm -rf $DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensstd0-${NENS}.1p0.monthly.nc
cdo ensmean $DATAOUT/$VAR/$exp.$CDATE.${VAR}.mem[0-${NENS}].1p0.monthly.nc \
$DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensmean0-${NENS}.1p0.monthly.nc

cdo ensstd $DATAOUT/$VAR/$exp.$CDATE.${VAR}.mem[0-${NENS}].1p0.monthly.nc \
$DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensstd0-${NENS}.1p0.monthly.nc

fi

done
