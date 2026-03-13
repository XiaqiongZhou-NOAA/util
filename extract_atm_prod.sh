#!/bin/bash
#-----------------------------------------------------------
# Invoke as: sbatch $script
#-----------------------------------------------------------
#SBATCH --ntasks=1 --nodes=1
#SBATCH -t 6:30:00
#SBATCH -A fv3-cpu
#SBATCH -q batch
#SBATCH -J fv3
#SBATCH -o ./log1
#SBATCH -e ./log1

set -euo pipefail

module load cdo
module load wgrib2


#######################################
# configuration
#######################################
WORKDIR=$PWD
cd $WORKDIR

DATAIN=/scratch4/NCEPDEV/stmp/Neil.Barton/RUNS/COMROOT/
exp=SFSBETA1.1_GFSv17ICs
DATAIN=/scratch3/NCEPDEV/global/Yangxing.Zheng/
exp=SFS_NRT_C192mx025_20260301
DATAIN=$DATAIN/$exp
DATAOUT=/scratch4/NCEPDEV/ensemble/$USER/util/sfs_diag/data

INTERPFLAG=YES  
NENS=30
CDATE=2026030100

pdy=${CDATE:0:8}

#######################################
# variable groups
#######################################

declare -A STREAM
declare -A DAILY

# acc monthly
for v in APCP ACPCP NCPCP DLWRFSFC USWRFSFC ULWRFTOA; do
STREAM[$v]="acc.monthly"
DAILY[$v]="NO"
done

# inst monthly
for v in T2M U10M V10M; do
STREAM[$v]="inst.monthly"
DAILY[$v]="NO"
done

# acc daily
for v in TCDC DSWRFSFC DSWRFTOA USWRFTOA ULWRFSFC; do
STREAM[$v]="acc.daily"
DAILY[$v]="YES"
done

# inst daily
for v in PWAT CAPE; do
STREAM[$v]="inst.daily"
DAILY[$v]="YES"
done

#######################################
# pattern mapping
#######################################

pattern(){

case $1 in
T2M) echo "TMP:2 m above ground" ;;
U10M) echo "UGRD:10 m above ground" ;;
V10M) echo "VGRD:10 m above ground" ;;
DLWRFSFC) echo "DLWRF:surface" ;;
DSWRFTOA) echo "DSWRF:top of atmosphere" ;;
DSWRFTOA) echo "DSWRF:surface" ;;
USWRFSFC) echo "USWRF:surface" ;;
USWRFTOA) echo "USWRF:top of atmosphere" ;;
ULWRFSFC) echo "ULWRF:surface" ;;
ULWRFTOA) echo "ULWRF:top of atmosphere" ;;
*) echo "$1" ;;
esac

}

#######################################
# main variable loop
#######################################

for VAR in "${!STREAM[@]}"; do
	echo VAR=$VAR

stream=${STREAM[$VAR]}
isdaily=${DAILY[$VAR]}

mkdir -p $DATAOUT/$VAR

#######################################
# ensemble loop
#######################################

for m in $(seq 0 $((NENS))); do

member=$(printf "%03d" $m)

tmpdir=./tmpdir.$CDATE.$exp/$VAR.$member
mkdir -p $tmpdir

#######################################
# month loop
#######################################

for mon in $(seq 0 11); do

validyyyymm=$(date -d "$pdy +$mon month" +%Y%m)

if [[ "$isdaily" == "YES" ]]; then
file=$DATAIN/sfs.$pdy/00/mem${member}/products/atmos/grib2/${stream}.mem${member}/${stream}.mem${member}.${pdy}00.${validyyyymm}.grib.t00z.grb2
else
file=$DATAIN/sfs.$pdy/00/mem${member}/products/atmos/grib2/${stream}.mem${member}/${stream}.${pdy}00.${validyyyymm}.grib.t00z.grb2
fi

[[ -f $file ]] || continue

pat=$(pattern $VAR)

echo "reading $file ($VAR)"

wgrib2 $file -match "$pat" -netcdf $tmpdir/${VAR}.${validyyyymm}.nc

done

#######################################
# output file
#######################################

outfile_name=$exp.$CDATE.${VAR}.mem${m}.1p0.monthly.nc
outfile=$DATAOUT/$VAR/$outfile_name

#######################################
# daily → monthly mean
#######################################

if [[ "$isdaily" == "YES" ]]; then

cdo mergetime $tmpdir/${VAR}.*.nc $tmpdir/all.nc
cdo monmean $tmpdir/all.nc $tmpdir/$outfile_name

else

cdo mergetime $tmpdir/${VAR}.*.nc $tmpdir/$outfile_name

fi

if [ $INTERPFLAG == "YES"  ];then

 cdo remapbil,r360x181 $tmpdir/$outfile_name $outfile
else
 mv $tmpdir/$outfile_name $outfile
fi
echo "saved $outfile"

rm -rf $tmpdir

done

#######################################
# ensemble statistics
#######################################

if [ "$NENS" -gt 0 ]; then

rm -rf $DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensmean0-${NENS}.1p0.monthly.nc
rm -rf $DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensstd0-${NENS}.1p0.monthly.nc
cdo ensmean $DATAOUT/$VAR/$exp.$CDATE.${VAR}.mem[0-${NENS}].1p0.monthly.nc \
$DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensmean0-${NENS}.1p0.monthly.nc

cdo ensstd $DATAOUT/$VAR/$exp.$CDATE.${VAR}.mem[0-${NENS}].1p0.monthly.nc \
$DATAOUT/$VAR/$exp.$CDATE.${VAR}.ensstd0-${NENS}.1p0.monthly.nc

fi

done
